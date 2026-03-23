create extension if not exists pgcrypto;

create table if not exists public.ai_generation_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default timezone('utc', now()),
  status text not null default 'pending' check (status in ('pending', 'success', 'error')),
  input_source text not null,
  output_type text not null,
  tone text,
  goal text,
  raw_input text not null,
  brand_snapshot jsonb not null default '{}'::jsonb,
  request_payload jsonb not null,
  response_payload jsonb,
  model_used text,
  cheap_model text,
  candidate_model text,
  image_model text,
  openrouter_request_id text,
  prompt_version text not null default 'sprint4-v1',
  error_message text
);

create index if not exists ai_generation_logs_created_at_idx
  on public.ai_generation_logs (created_at desc);

create index if not exists ai_generation_logs_status_idx
  on public.ai_generation_logs (status);

alter table public.ai_generation_logs enable row level security;
