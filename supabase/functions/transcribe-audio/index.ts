import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
const OPENROUTER_TEXT_MODEL = Deno.env.get('OPENROUTER_TEXT_MODEL') ?? 'google/gemini-3-flash-preview'
const OPENROUTER_TRANSCRIBE_MODEL = Deno.env.get('OPENROUTER_TRANSCRIBE_MODEL') ?? 'google/gemini-3.1-flash-lite-preview'
const OPENROUTER_APP_URL = Deno.env.get('OPENROUTER_APP_URL') ?? 'https://kadro.app'
const OPENROUTER_APP_NAME = Deno.env.get('OPENROUTER_APP_NAME') ?? 'Kadro'

type OpenRouterResponse = {
  id?: string
  model?: string
  choices?: Array<{
    message?: {
      content?: string | Array<{ type?: string; text?: string }>
    }
  }>
}

type TranscriptionAttempt = {
  response: OpenRouterResponse
  transcript: string
  fallbackUsed: boolean
  fallbackReason: string
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

  let formData: FormData
  try {
    formData = await req.formData()
  } catch {
    return json({ error: 'Request body must be multipart/form-data.' }, 400)
  }

  const file = formData.get('file')
  const languageHint = formData.get('language_hint')?.toString().trim() || 'Русский'

  if (!(file instanceof File)) {
    return json({ error: 'Audio file is required.' }, 400)
  }

  const bytes = new Uint8Array(await file.arrayBuffer())
  if (bytes.byteLength === 0) {
    return json({ error: 'Audio file is empty.' }, 400)
  }

  if (bytes.byteLength > 20 * 1024 * 1024) {
    return json({ error: 'Audio file is too large. Keep voice notes under 20 MB.' }, 400)
  }

  const format = inferAudioFormat(file)

  try {
    const attempt = await transcribeWithFallback(bytes, format, languageHint)
    return json({
      transcript: attempt.transcript,
      model: attempt.response.model ?? OPENROUTER_TRANSCRIBE_MODEL,
      openrouter_request_id: attempt.response.id ?? '',
      fallback_used: attempt.fallbackUsed,
      fallback_reason: attempt.fallbackReason,
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown transcription error'
    return json({ error: message }, 500)
  }
})

async function transcribeWithFallback(
  bytes: Uint8Array,
  format: string,
  languageHint: string
): Promise<TranscriptionAttempt> {
  try {
    const response = await callOpenRouter(OPENROUTER_TRANSCRIBE_MODEL, bytes, format, languageHint)
    return {
      response,
      transcript: extractTranscript(response),
      fallbackUsed: false,
      fallbackReason: '',
    }
  } catch (primaryError) {
    const primaryMessage = primaryError instanceof Error ? primaryError.message : 'Primary transcription failed.'

    if (!OPENROUTER_TEXT_MODEL || OPENROUTER_TEXT_MODEL === OPENROUTER_TRANSCRIBE_MODEL) {
      throw new Error(primaryMessage)
    }

    try {
      const response = await callOpenRouter(OPENROUTER_TEXT_MODEL, bytes, format, languageHint)
      return {
        response,
        transcript: extractTranscript(response),
        fallbackUsed: true,
        fallbackReason: `Primary transcription fallback: ${primaryMessage}`,
      }
    } catch (fallbackError) {
      const fallbackMessage = fallbackError instanceof Error ? fallbackError.message : 'Fallback transcription failed.'
      throw new Error(`Primary failed: ${primaryMessage} | Fallback failed: ${fallbackMessage}`)
    }
  }
}

async function callOpenRouter(
  model: string,
  bytes: Uint8Array,
  format: string,
  languageHint: string
): Promise<OpenRouterResponse> {
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${OPENROUTER_API_KEY}`,
      'Content-Type': 'application/json',
      'HTTP-Referer': OPENROUTER_APP_URL,
      'X-Title': OPENROUTER_APP_NAME,
    },
    body: JSON.stringify({
      model,
      temperature: 0,
      max_tokens: 1200,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: buildTranscriptionPrompt(languageHint),
            },
            {
              type: 'input_audio',
              input_audio: {
                data: bytesToBase64(bytes),
                format,
              },
            },
          ],
        },
      ],
    }),
  })

  const responseText = await response.text()
  if (!response.ok) {
    throw new Error(`OpenRouter error ${response.status}: ${responseText}`)
  }

  try {
    return JSON.parse(responseText) as OpenRouterResponse
  } catch {
    throw new Error('OpenRouter returned non-JSON response.')
  }
}

function extractTranscript(response: OpenRouterResponse): string {
  const content = response.choices?.[0]?.message?.content
  const rawText = Array.isArray(content)
    ? content
        .map((part) => (part.type === 'text' ? part.text ?? '' : ''))
        .join('')
        .trim()
    : (content ?? '').trim()

  if (!rawText) {
    throw new Error('Transcription response was empty.')
  }

  return rawText
    .replace(/^transcript\s*:\s*/i, '')
    .replace(/^раcшифровка\s*:\s*/i, '')
    .trim()
}

function buildTranscriptionPrompt(languageHint: string): string {
  return [
    'Transcribe this voice note faithfully.',
    'Return only the transcript text.',
    'Do not summarize.',
    'Do not add comments, labels, markdown, or explanations.',
    `Preferred output language: ${languageHint}.`,
    'If the original speech is in Russian, output clean Russian transcript with punctuation.',
  ].join(' ')
}

function inferAudioFormat(file: File): string {
  const mime = file.type.toLowerCase()
  const name = file.name.toLowerCase()

  if (mime.includes('wav') || name.endsWith('.wav')) return 'wav'
  if (mime.includes('mpeg') || name.endsWith('.mp3')) return 'mp3'
  if (mime.includes('aac') || name.endsWith('.aac')) return 'aac'
  return 'm4a'
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
