alter table public.ai_generation_logs
  add column if not exists fallback_used boolean not null default false,
  add column if not exists fallback_reason text;
