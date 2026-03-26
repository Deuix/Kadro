import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CODEFAST_API_KEY = Deno.env.get('CODEFAST_API_KEY')
const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
const OPENROUTER_IMAGE_MODEL = Deno.env.get('OPENROUTER_IMAGE_MODEL') ?? 'google/gemini-3.1-flash-image-preview'
const OPENROUTER_APP_URL = Deno.env.get('OPENROUTER_APP_URL') ?? 'https://kadro.app'
const OPENROUTER_APP_NAME = Deno.env.get('OPENROUTER_APP_NAME') ?? 'Kadro'
const CODEFAST_BASE_URL = 'https://geminiapi.codefast.app'
const CODEFAST_MODEL = 'gemini-3.1-flash'
const PROMPT_VERSION = 'style-visual-v4-codefast-primary'

type GenerateStyleVisualBody = {
  project_title?: string
  raw_input?: string
  output_type?: string
  visual_kind?: string
  aspect_ratio?: string
  primary_text?: string
  secondary_text?: string
  style_pack_id?: string
  style_pack_name?: string
  style_pack_prompt_template?: string
  style_pack_negative_prompt?: string
  style_pack_reference_folder?: string
  reference_images?: Array<{
    filename?: string
    data_url?: string
  }>
  base_image_data_url?: string
  prompt_override?: string
}

type CodefastCreateResponse = {
  jobId?: string
  job_id?: string
  status?: string
}

type CodefastStatusResponse = {
  jobId?: string
  model?: string
  queue?: {
    status?: string
  }
  job?: {
    status?: string
    error?: string | null
    result?: Record<string, unknown>
  }
}

type OpenRouterImageResponse = {
  id?: string
  model?: string
  choices?: Array<{
    message?: {
      images?: Array<{
        image_url?: {
          url?: string
        }
      }>
      content?: unknown
    }
  }>
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405)
  }

  let body: GenerateStyleVisualBody
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Request body must be valid JSON.' }, 400)
  }

  const stylePackID = body.style_pack_id?.trim() ?? ''
  const primaryText = body.primary_text?.trim() ?? ''
  const references = (body.reference_images ?? []).filter((item) => item.data_url).slice(0, 2)

  if (!stylePackID) {
    return json({ error: 'style_pack_id is required.' }, 400)
  }

  if (!primaryText) {
    return json({ error: 'primary_text is required.' }, 400)
  }

  const prompt = buildPrompt(body)
  const referenceFilenames = references.map((reference) => reference.filename ?? '').filter(Boolean)
  const visualKind = body.visual_kind ?? 'cover'
  const shouldBypassCodefastForExactRatio = prefersExactAspectRatio(body.aspect_ratio) && Boolean(OPENROUTER_API_KEY)
  let codefastErrorMessage: string | null = null

  if (CODEFAST_API_KEY && !shouldBypassCodefastForExactRatio) {
    try {
      const result = await generateWithCodefast(body, prompt)
      return json({
        image_data_url: result.imageDataURL,
        model: result.model,
        openrouter_request_id: result.requestID,
        prompt_version: PROMPT_VERSION,
        style_pack_id: stylePackID,
        reference_count: referenceFilenames.length,
        reference_filenames: referenceFilenames,
        visual_kind: visualKind,
        prompt_used: prompt,
      })
    } catch (error) {
      codefastErrorMessage = error instanceof Error ? error.message : 'Unknown Codefast image generation error'
      console.error('Codefast image generation failed, trying OpenRouter fallback if configured:', codefastErrorMessage)
      if (!OPENROUTER_API_KEY) {
        return json({ error: codefastErrorMessage }, 500)
      }
    }
  }

  if (!OPENROUTER_API_KEY) {
    return json({ error: 'No image provider configured. Add CODEFAST_API_KEY or OPENROUTER_API_KEY.' }, 500)
  }

  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': OPENROUTER_APP_URL,
        'X-Title': OPENROUTER_APP_NAME,
      },
      body: JSON.stringify({
        model: OPENROUTER_IMAGE_MODEL,
        modalities: ['image', 'text'],
        image_config: {
          aspect_ratio: body.aspect_ratio?.trim() || '4:5',
          image_size: '0.5K',
        },
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: prompt },
              ...references.map((reference) => ({
                type: 'image_url',
                image_url: { url: reference.data_url },
              })),
            ],
          },
        ],
      }),
    })

    const responseText = await response.text()
    if (!response.ok) {
      throw new Error(`OpenRouter error ${response.status}: ${responseText}`)
    }

    const parsed = JSON.parse(responseText) as OpenRouterImageResponse
    const rawImageURL = parsed.choices?.[0]?.message?.images?.[0]?.image_url?.url
    if (!rawImageURL) {
      throw new Error('OpenRouter image generation response did not include an image.')
    }

    const imageDataURL = await normalizeToDataURL(rawImageURL)

    return json({
      image_data_url: imageDataURL,
      model: parsed.model ?? OPENROUTER_IMAGE_MODEL,
      openrouter_request_id: parsed.id ?? '',
      prompt_version: PROMPT_VERSION,
      style_pack_id: stylePackID,
      reference_count: referenceFilenames.length,
      reference_filenames: referenceFilenames,
      visual_kind: visualKind,
      prompt_used: prompt,
    })
  } catch (error) {
    const fallbackMessage = error instanceof Error ? error.message : 'Unknown style visual generation error'
    const message = codefastErrorMessage
      ? `Codefast: ${codefastErrorMessage} | OpenRouter fallback: ${fallbackMessage}`
      : fallbackMessage
    return json({ error: message, codefast_error: codefastErrorMessage }, 500)
  }
})

async function generateWithCodefast(body: GenerateStyleVisualBody, prompt: string) {
  const aspectRatio = mapAspectRatio(body.aspect_ratio)
  const baseImage = extractBase64FromDataURL(body.base_image_data_url)
  const referenceImages = (body.reference_images ?? [])
    .map((reference) => extractBase64FromDataURL(reference.data_url))
    .filter((reference): reference is { mimeType: string; base64: string } => Boolean(reference))
    .slice(0, 2)

  let endpoint = '/v1/image'
  let payload: Record<string, unknown> = {
    prompt,
    model: CODEFAST_MODEL,
    aspect_ratio: aspectRatio,
  }
  let preferredMimeType = 'image/png'

  if (baseImage) {
    endpoint = '/v1/image/variation'
    payload = {
      prompt,
      image: baseImage.base64,
      model: CODEFAST_MODEL,
      mime_type: baseImage.mimeType,
      aspect_ratio: aspectRatio,
    }
    preferredMimeType = baseImage.mimeType
  } else if (referenceImages.length > 0) {
    endpoint = '/v1/image/from-references'
    payload = {
      prompt,
      images: referenceImages.map((reference) => reference.base64),
      model: CODEFAST_MODEL,
      aspect_ratio: aspectRatio,
    }
    preferredMimeType = referenceImages[0]?.mimeType ?? preferredMimeType
  }

  const createResponse = await fetch(`${CODEFAST_BASE_URL}${endpoint}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${CODEFAST_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  })

  const createText = await createResponse.text()
  if (!createResponse.ok) {
    throw new Error(`Codefast create error ${createResponse.status}: ${createText}`)
  }

  const created = JSON.parse(createText) as CodefastCreateResponse
  const jobId = created.jobId ?? created.job_id
  if (!jobId) {
    throw new Error('Codefast did not return a jobId.')
  }

  const status = await pollCodefastJob(jobId)
  const model = status.model ?? CODEFAST_MODEL
  const result = status.job?.result
  const base64Image = extractCodefastBase64(result)

  if (base64Image) {
    return {
      imageDataURL: `data:${preferredMimeType};base64,${base64Image}`,
      model,
      requestID: jobId,
    }
  }

  const storageURL = extractCodefastImageURL(result)
  if (!storageURL) {
    const debugSnippet = JSON.stringify(result ?? status.job ?? status).slice(0, 600)
    throw new Error(`Codefast job completed without image output. Result: ${debugSnippet}`)
  }

  const imageDataURL = await normalizeToDataURL(storageURL)
  return {
    imageDataURL,
    model,
    requestID: jobId,
  }
}

async function pollCodefastJob(jobId: string): Promise<CodefastStatusResponse> {
  const maxAttempts = 45
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const response = await fetch(`${CODEFAST_BASE_URL}/v1/image/status`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${CODEFAST_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ job_id: jobId }),
    })

    const text = await response.text()
    if (!response.ok) {
      throw new Error(`Codefast status error ${response.status}: ${text}`)
    }

    const payload = JSON.parse(text) as CodefastStatusResponse
    const status = payload.job?.status ?? payload.queue?.status

    if (status === 'SUCCESS') {
      return payload
    }
    if (status === 'FAILED' || status === 'ERROR' || status === 'CANCELED') {
      throw new Error(payload.job?.error || `Codefast job ${status}.`)
    }

    await sleep(2000)
  }

  throw new Error('Codefast job timed out while waiting for image generation.')
}

function buildPrompt(body: GenerateStyleVisualBody): string {
  const stylePackName = body.style_pack_name?.trim() || body.style_pack_id || 'selected style pack'
  const visualKind = body.visual_kind?.trim() || 'cover visual'
  const outputType = body.output_type?.trim() || 'post'
  const primaryText = body.primary_text?.trim() || ''
  const secondaryText = body.secondary_text?.trim() || ''
  const promptTemplate = body.style_pack_prompt_template?.trim() || ''
  const negativePrompt = body.style_pack_negative_prompt?.trim() || ''
  const rawInput = body.raw_input?.trim() || ''
  const promptOverride = body.prompt_override?.trim() || ''
  const aspectRatioInstruction = buildAspectRatioInstruction(body.aspect_ratio)

  const promptParts = [
    `Create a premium ${visualKind} for an Instagram ${outputType}.`,
    aspectRatioInstruction,
    body.base_image_data_url
      ? `Treat the provided base image as the current carousel art direction. Preserve the same visual family, palette discipline, hierarchy logic, and premium feel while creating a fresh composition.`
      : `Use the attached reference images only as inspiration for visual language, spacing, typography mood, palette discipline, and composition rhythm.`,
    `Do not copy any exact layout, logo, brand mark, text arrangement, or distinctive composition from references or previous visuals.`,
    `Selected style pack: ${stylePackName}.`,
    promptTemplate,
    primaryText ? `Primary text to render clearly: "${primaryText}".` : '',
    secondaryText ? `Secondary text to render only if it improves hierarchy: "${secondaryText}".` : '',
    rawInput ? `Content context: ${rawInput}` : '',
    `Prioritize mobile legibility, strong hierarchy, and premium editorial taste.`,
    body.style_pack_id === 'texty'
      ? `This is a text-led visual. Typography should dominate. Keep decorative elements minimal.`
      : `Keep the style visually consistent with previous visuals in this carousel.`,
    promptOverride ? `User regeneration instruction: ${promptOverride}` : '',
    negativePrompt ? `Avoid: ${negativePrompt}` : '',
    `No watermarks. No mockup frames.`,
  ].filter(Boolean)

  return promptParts.join(' ')
}

function buildAspectRatioInstruction(aspectRatio?: string) {
  switch ((aspectRatio || '').trim()) {
    case '1:1':
      return 'Canvas must be square 1:1 for an Instagram feed post. Do not compose it like a story.'
    case '4:5':
      return 'Canvas must be 4:5 feed portrait. This is not a 9:16 story layout.'
    case '9:16':
      return 'Canvas must be full-height 9:16 story format.'
    case '16:9':
      return 'Canvas must be 16:9 landscape.'
    default:
      return ''
  }
}

function prefersExactAspectRatio(aspectRatio?: string) {
  switch ((aspectRatio || '').trim()) {
    case '4:5':
    case '9:16':
      return true
    default:
      return false
  }
}

function mapAspectRatio(aspectRatio?: string) {
  switch ((aspectRatio || '').trim()) {
    case '1:1':
      return 'square'
    case '16:9':
      return 'landscape'
    default:
      return 'portrait'
  }
}

function extractBase64FromDataURL(dataURL?: string) {
  if (!dataURL) return null
  const match = dataURL.match(/^data:(.+?);base64,(.+)$/)
  if (!match) return null
  return { mimeType: match[1], base64: match[2] }
}

function extractCodefastBase64(result?: Record<string, unknown>) {
  if (!result) return null

  const directImages = result['images']
  if (Array.isArray(directImages)) {
    for (const item of directImages) {
      if (typeof item === 'string' && item && !item.startsWith('http')) {
        return item
      }
      if (item && typeof item === 'object') {
        const nested = item as Record<string, unknown>
        const nestedBase64 = nested['base64'] ?? nested['image'] ?? nested['data']
        if (typeof nestedBase64 === 'string' && nestedBase64 && !nestedBase64.startsWith('http')) {
          return nestedBase64
        }
      }
    }
  }

  const directImage = result['image']
  if (typeof directImage === 'string' && directImage && !directImage.startsWith('http')) {
    return directImage
  }
  if (directImage && typeof directImage === 'object') {
    const nested = directImage as Record<string, unknown>
    const nestedBase64 = nested['base64'] ?? nested['image'] ?? nested['data']
    if (typeof nestedBase64 === 'string' && nestedBase64 && !nestedBase64.startsWith('http')) {
      return nestedBase64
    }
  }

  return null
}

function extractCodefastImageURL(result?: Record<string, unknown>) {
  if (!result) return null

  const candidateKeys = ['storage_url', 'storageUrl', 'image_url', 'imageUrl', 'url']
  for (const key of candidateKeys) {
    const value = result[key]
    if (typeof value === 'string' && value) {
      return value
    }
  }

  const storageURLs = result['storage_urls']
  if (Array.isArray(storageURLs)) {
    const firstURL = storageURLs.find((item) => typeof item === 'string' && item) as string | undefined
    if (firstURL) return firstURL
  }

  const directImages = result['images']
  if (Array.isArray(directImages)) {
    for (const item of directImages) {
      if (typeof item === 'string' && item.startsWith('http')) {
        return item
      }
      if (item && typeof item === 'object') {
        const nested = item as Record<string, unknown>
        for (const key of candidateKeys) {
          const value = nested[key]
          if (typeof value === 'string' && value) {
            return value
          }
        }
      }
    }
  }

  const directImage = result['image']
  if (typeof directImage === 'string' && directImage.startsWith('http')) {
    return directImage
  }
  if (directImage && typeof directImage === 'object') {
    const nested = directImage as Record<string, unknown>
    for (const key of candidateKeys) {
      const value = nested[key]
      if (typeof value === 'string' && value) {
        return value
      }
    }
  }

  return null
}

async function normalizeToDataURL(rawURL: string): Promise<string> {
  if (rawURL.startsWith('data:')) {
    return rawURL
  }

  const response = await fetch(rawURL)
  if (!response.ok) {
    throw new Error(`Failed to fetch generated image: ${response.status}`)
  }

  const mimeType = response.headers.get('content-type') || 'image/png'
  const bytes = new Uint8Array(await response.arrayBuffer())
  return `data:${mimeType};base64,${bytesToBase64(bytes)}`
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = ''
  const chunkSize = 0x8000

  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize)
    binary += String.fromCharCode(...chunk)
  }

  return btoa(binary)
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}
