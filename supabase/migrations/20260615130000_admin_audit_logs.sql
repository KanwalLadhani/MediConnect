create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles(id) on delete set null,
  type text not null check (length(trim(type)) > 0),
  action text not null check (length(trim(action)) > 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists audit_logs_actor_created_idx
on public.audit_logs(actor_user_id, created_at desc);

create index if not exists audit_logs_type_created_idx
on public.audit_logs(type, created_at desc);

alter table public.audit_logs enable row level security;

drop policy if exists "Admins can read audit logs" on public.audit_logs;
create policy "Admins can read audit logs"
on public.audit_logs for select
using (public.is_admin());

drop policy if exists "Admins can create audit logs" on public.audit_logs;
create policy "Admins can create audit logs"
on public.audit_logs for insert
with check (public.is_admin());
