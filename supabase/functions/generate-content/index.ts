import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const OPENROUTER_API_KEY = Deno.env.get('OPENROUTER_API_KEY')
const OPENROUTER_TEXT_MODEL = Deno.env.get('OPENROUTER_TEXT_MODEL') ?? 'google/gemini-3-flash-preview'
const OPENROUTER_CHEAP_MODEL = Deno.env.get('OPENROUTER_CHEAP_MODEL') ?? 'openai/gpt-5-nano'
const OPENROUTER_IMAGE_MODEL = Deno.env.get('OPENROUTER_IMAGE_MODEL') ?? 'google/gemini-3.1-flash-image-preview'
const OPENROUTER_CANDIDATE_MODEL = Deno.env.get('OPENROUTER_CANDIDATE_MODEL') ?? 'bytedance/seed-2.0-lite'
const OPENROUTER_APP_URL = Deno.env.get('OPENROUTER_APP_URL') ?? 'https://kadro.app'
const OPENROUTER_APP_NAME = Deno.env.get('OPENROUTER_APP_NAME') ?? 'Kadro'
const PROMPT_VERSION = 'sprint4-v2'

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

type GenerateContentBody = {
  input_source?: string
  raw_input?: string
  output_type?: string
  tone?: string
  goal?: string
  platform?: string
  include_candidate_preview?: boolean
  brand_profile?: {
    brand_name?: string
    niche?: string
    language?: string
    audience?: string
    user_type?: string
    tone_expert_simple?: number
    tone_warm_strict?: number
    tone_bold_neutral?: number
    tone_short_detailed?: number
    words_to_use?: string
    words_to_avoid?: string
    cta_style?: string
    favorite_phrases?: string
    visual_mood?: string
    selected_style_pack_id?: string
    selected_style_pack_name?: string
    style_pack_prompt_template?: string
    style_pack_negative_prompt?: string
    style_pack_reference_folder?: string
    palette_preference?: string
    cover_style?: string
    best_examples?: string
  }
}

type OpenRouterResponse = {
  id?: string
  model?: string
  usage?: Record<string, unknown>
  choices?: Array<{
    message?: {
      content?: string | Array<{ type?: string; text?: string }>
    }
  }>
}

type GenerationAttempt = {
  response: OpenRouterResponse
  generated: Record<string, unknown>
  fallbackUsed: boolean
  fallbackReason: string
}

const contentSchema = {
  type: 'object',
  additionalProperties: false,
  required: [
    'title',
    'summary',
    'hook',
    'main_text',
    'cta',
    'short_version',
    'caption',
    'hashtags',
    'carousel',
    'reels',
    'stories',
    'variants',
    'suggested_next_actions',
  ],
  properties: {
    title: { type: 'string' },
    summary: { type: 'string' },
    hook: { type: 'string' },
    main_text: { type: 'string' },
    cta: { type: 'string' },
    short_version: { type: 'string' },
    caption: { type: 'string' },
    hashtags: {
      type: 'array',
      items: { type: 'string' },
      minItems: 0,
      maxItems: 12,
    },
    carousel: {
      type: 'object',
      additionalProperties: false,
      required: ['cover_title', 'slides'],
      properties: {
        cover_title: { type: 'string' },
        slides: {
          type: 'array',
          items: {
            type: 'object',
            additionalProperties: false,
            required: ['headline', 'body', 'cta'],
            properties: {
              headline: { type: 'string' },
              body: { type: 'string' },
              cta: { type: 'string' },
            },
          },
          minItems: 0,
          maxItems: 10,
        },
      },
    },
    reels: {
      type: 'object',
      additionalProperties: false,
      required: ['hook', 'script_beats', 'on_screen_text', 'caption', 'cover_idea'],
      properties: {
        hook: { type: 'string' },
        script_beats: {
          type: 'array',
          items: { type: 'string' },
          minItems: 0,
          maxItems: 8,
        },
        on_screen_text: {
          type: 'array',
          items: { type: 'string' },
          minItems: 0,
          maxItems: 8,
        },
        caption: { type: 'string' },
        cover_idea: { type: 'string' },
      },
    },
    stories: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['title', 'body', 'sticker_idea'],
        properties: {
          title: { type: 'string' },
          body: { type: 'string' },
          sticker_idea: { type: 'string' },
        },
      },
      minItems: 0,
      maxItems: 6,
    },
    variants: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['label', 'text'],
        properties: {
          label: { type: 'string' },
          text: { type: 'string' },
        },
      },
      minItems: 0,
      maxItems: 4,
    },
    suggested_next_actions: {
      type: 'array',
      items: { type: 'string' },
      minItems: 0,
      maxItems: 5,
    },
  },
} as const

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

  let body: GenerateContentBody
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Request body must be valid JSON.' }, 400)
  }

  const rawInput = body.raw_input?.trim() ?? ''
  const outputType = body.output_type?.trim() ?? ''

  if (!rawInput) {
    return json({ error: 'raw_input is required.' }, 400)
  }

  if (!outputType) {
    return json({ error: 'output_type is required.' }, 400)
  }

  const requestPayload = {
    input_source: body.input_source ?? '',
    raw_input: rawInput,
    output_type: outputType,
    tone: body.tone ?? '',
    goal: body.goal ?? '',
    platform: body.platform ?? 'Instagram',
    include_candidate_preview: body.include_candidate_preview ?? false,
    brand_profile: body.brand_profile ?? {},
  }

  const { data: insertedLog } = await supabaseAdmin
    .from('ai_generation_logs')
    .insert({
      status: 'pending',
      input_source: requestPayload.input_source,
      output_type: requestPayload.output_type,
      tone: requestPayload.tone,
      goal: requestPayload.goal,
      raw_input: requestPayload.raw_input,
      brand_snapshot: requestPayload.brand_profile,
      request_payload: requestPayload,
      prompt_version: PROMPT_VERSION,
      cheap_model: OPENROUTER_CHEAP_MODEL,
      candidate_model: OPENROUTER_CANDIDATE_MODEL,
      image_model: OPENROUTER_IMAGE_MODEL,
    })
    .select('id')
    .single()

  const logId = insertedLog?.id

  try {
    const attempt = await generateWithFallback(requestPayload)
    const responsePayload = {
      ...attempt.generated,
      metadata: {
        text_model: attempt.response.model ?? OPENROUTER_TEXT_MODEL,
        cheap_model: OPENROUTER_CHEAP_MODEL,
        image_model: OPENROUTER_IMAGE_MODEL,
        candidate_model: OPENROUTER_CANDIDATE_MODEL,
        openrouter_request_id: attempt.response.id ?? '',
        prompt_version: PROMPT_VERSION,
        fallback_used: attempt.fallbackUsed,
        fallback_reason: attempt.fallbackReason,
      },
    }

    if (logId) {
      await supabaseAdmin
        .from('ai_generation_logs')
        .update({
          status: 'success',
          model_used: attempt.response.model ?? OPENROUTER_TEXT_MODEL,
          openrouter_request_id: attempt.response.id ?? null,
          response_payload: responsePayload,
          fallback_used: attempt.fallbackUsed,
          fallback_reason: attempt.fallbackReason || null,
        })
        .eq('id', logId)
    }

    return json(responsePayload, 200)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'

    if (logId) {
      await supabaseAdmin
        .from('ai_generation_logs')
        .update({
          status: 'error',
          error_message: message,
        })
        .eq('id', logId)
    }

    return json({ error: message }, 500)
  }
})

async function generateWithFallback(payload: Record<string, unknown>): Promise<GenerationAttempt> {
  try {
    const response = await callOpenRouter(OPENROUTER_TEXT_MODEL, payload)
    const generated = extractStructuredContent(response)
    return {
      response,
      generated,
      fallbackUsed: false,
      fallbackReason: '',
    }
  } catch (primaryError) {
    const primaryMessage = primaryError instanceof Error ? primaryError.message : 'Primary generation failed.'

    if (!OPENROUTER_CANDIDATE_MODEL || OPENROUTER_CANDIDATE_MODEL === OPENROUTER_TEXT_MODEL) {
      throw new Error(primaryMessage)
    }

    try {
      const response = await callOpenRouter(OPENROUTER_CANDIDATE_MODEL, payload)
      const generated = extractStructuredContent(response)
      return {
        response,
        generated,
        fallbackUsed: true,
        fallbackReason: `Primary model fallback: ${primaryMessage}`,
      }
    } catch (candidateError) {
      const candidateMessage = candidateError instanceof Error ? candidateError.message : 'Candidate generation failed.'
      throw new Error(`Primary failed: ${primaryMessage} | Candidate failed: ${candidateMessage}`)
    }
  }
}

async function callOpenRouter(model: string, payload: Record<string, unknown>): Promise<OpenRouterResponse> {
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
      temperature: 0.7,
      max_tokens: 2200,
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'kadro_content_package',
          strict: true,
          schema: contentSchema,
        },
      },
      messages: [
        {
          role: 'system',
          content: buildSystemPrompt(),
        },
        {
          role: 'user',
          content: buildUserPrompt(payload),
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

function extractStructuredContent(response: OpenRouterResponse) {
  const messageContent = response.choices?.[0]?.message?.content

  const rawText = Array.isArray(messageContent)
    ? messageContent
        .map((part) => (part.type === 'text' ? part.text ?? '' : ''))
        .join('')
    : messageContent ?? ''

  if (!rawText.trim()) {
    throw new Error('OpenRouter returned empty content.')
  }

  try {
    return JSON.parse(rawText) as Record<string, unknown>
  } catch {
    throw new Error('Structured JSON parsing failed.')
  }
}

function buildSystemPrompt() {
  return [
    'You are Kadro, a premium iPhone-first AI content strategist for creators, experts, and small businesses.',
    'Turn raw thoughts into publish-ready social content packages.',
    'Always produce concise, high-signal, modern, non-generic content.',
    'Avoid cliché AI wording, filler, and corporate fluff.',
    'Respect the brand profile if provided.',
    'Keep the output highly structured and usable in a mobile editor.',
    'Do not use markdown. Do not wrap JSON in code fences.',
    'If a section is not relevant, return an empty string or empty array, not null.',
    'For carousel outputs keep slides compact and legible.',
    'For reels outputs make beats punchy and easy to film.',
    'For stories outputs make frames short, sequential, and interactive.',
  ].join(' ')
}

function buildUserPrompt(payload: Record<string, unknown>) {
  return [
    'Generate a publish-ready social content package using this request.',
    'Output language must follow brand_profile.language when present; otherwise use Russian.',
    'The content should feel premium, human, clear, and tasteful.',
    'Prioritize strong hooks, clean structure, and high readability.',
    'Use brand words when useful and avoid banned words if supplied.',
    'If brand_profile contains a selected style pack, preserve that creative direction in carousel covers, visual suggestions, and aesthetic language.',
    'Treat style_pack_prompt_template as a visual north star and style_pack_negative_prompt as constraints for future image generation.',
    'If output_type is post, prioritize hook + main_text + cta + short_version + hashtags.',
    'If output_type is carousel, prioritize cover_title + 5-8 slides with concise copy.',
    'If output_type is reels, prioritize hook + script_beats + on_screen_text + caption + cover_idea.',
    'If output_type is stories, prioritize 4-6 sequential story frames.',
    'If output_type is content_pack, fill as many sections as useful while staying compact.',
    '',
    JSON.stringify(payload, null, 2),
  ].join('\n')
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
