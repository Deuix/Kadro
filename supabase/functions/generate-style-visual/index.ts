import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
const OPENROUTER_IMAGE_MODEL = Deno.env.get('OPENROUTER_IMAGE_MODEL') ?? 'google/gemini-3.1-flash-image-preview'
const OPENROUTER_APP_URL = Deno.env.get('OPENROUTER_APP_URL') ?? 'https://kadro.app'
const OPENROUTER_APP_NAME = Deno.env.get('OPENROUTER_APP_NAME') ?? 'Kadro'
const PROMPT_VERSION = 'style-visual-v1'

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

  if (!OPENROUTER_API_KEY) {
    return json({ error: 'OPENROUTER_API_KEY is missing in Supabase secrets.' }, 500)
  }

  let body: GenerateStyleVisualBody
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Request body must be valid JSON.' }, 400)
  }

  const stylePackID = body.style_pack_id?.trim() ?? ''
  const primaryText = body.primary_text?.trim() ?? ''
  const aspectRatio = body.aspect_ratio?.trim() || '4:5'
  const references = (body.reference_images ?? []).filter((item) => item.data_url)

  if (!stylePackID) {
    return json({ error: 'style_pack_id is required.' }, 400)
  }

  if (!primaryText) {
    return json({ error: 'primary_text is required.' }, 400)
  }

  if (references.length === 0) {
    return json({ error: 'At least one reference image is required.' }, 400)
  }

  const prompt = buildPrompt(body)

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
          aspect_ratio: aspectRatio,
        },
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: prompt,
              },
              ...references.map((reference) => ({
                type: 'image_url',
                image_url: {
                  url: reference.data_url,
                },
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
    const rawImageURL = await extractImageURL(parsed)
    const imageDataURL = await normalizeToDataURL(rawImageURL)

    return json({
      image_data_url: imageDataURL,
      model: parsed.model ?? OPENROUTER_IMAGE_MODEL,
      openrouter_request_id: parsed.id ?? '',
      prompt_version: PROMPT_VERSION,
      style_pack_id: stylePackID,
      reference_count: references.length,
      reference_filenames: references.map((reference) => reference.filename ?? ''),
      visual_kind: body.visual_kind ?? 'cover',
      prompt_used: prompt,
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown style visual generation error'
    return json({ error: message }, 500)
  }
})

function buildPrompt(body: GenerateStyleVisualBody): string {
  const stylePackName = body.style_pack_name?.trim() || body.style_pack_id || 'selected style pack'
  const visualKind = body.visual_kind?.trim() || 'cover visual'
  const outputType = body.output_type?.trim() || 'post'
  const primaryText = body.primary_text?.trim() || ''
  const secondaryText = body.secondary_text?.trim() || ''
  const promptTemplate = body.style_pack_prompt_template?.trim() || ''
  const negativePrompt = body.style_pack_negative_prompt?.trim() || ''
  const rawInput = body.raw_input?.trim() || ''

  const promptParts = [
    `Create a premium ${visualKind} for an Instagram ${outputType}.`,
    `Use the attached reference images only as inspiration for visual language, spacing, typography mood, palette discipline, and composition rhythm.`,
    `Do not copy any exact layout, logo, brand mark, text arrangement, or distinctive composition from the references.`,
    `Selected style pack: ${stylePackName}.`,
    promptTemplate,
    primaryText ? `Primary text to render clearly: "${primaryText}".` : '',
    secondaryText ? `Secondary text to render only if it improves hierarchy: "${secondaryText}".` : '',
    rawInput ? `Content context: ${rawInput}` : '',
    `Prioritize mobile legibility, strong hierarchy, and premium editorial taste.`,
    body.style_pack_id === 'texty'
      ? `This is a text-led visual. Typography should dominate. Keep decorative elements minimal.`
      : `Use restrained supporting visuals and keep the composition clean and modern.`,
    negativePrompt ? `Avoid: ${negativePrompt}` : '',
    `No watermarks. No mockup frames. No generic AI glow unless the references clearly justify it.`,
  ].filter(Boolean)

  return promptParts.join(' ')
}

async function extractImageURL(response: OpenRouterImageResponse): Promise<string> {
  const imageURL = response.choices?.[0]?.message?.images?.[0]?.image_url?.url
  if (imageURL) return imageURL
  throw new Error('Image generation response did not include an image.')
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

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}
