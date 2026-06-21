create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('patient', 'health_worker', 'admin')),
  full_name text not null,
  phone text,
  email text,
  preferred_language text not null default 'en' check (preferred_language in ('en', 'ur')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.patients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  gender text,
  date_of_birth date,
  address text,
  city text not null,
  emergency_contact_name text,
  emergency_contact_phone text,
  medical_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.health_workers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  worker_type text not null check (
    worker_type in (
      'doctor',
      'nurse',
      'male_nurse',
      'ot_technician',
      'dispenser',
      'lab_collector',
      'other'
    )
  ),
  qualification text not null,
  experience_years integer,
  bio text,
  city text not null,
  service_area text,
  verification_status text not null default 'pending' check (
    verification_status in ('pending', 'approved', 'rejected', 'suspended')
  ),
  rejection_reason text,
  is_available boolean not null default false,
  average_rating numeric(3, 2) not null default 0,
  total_reviews integer not null default 0,
  total_completed_orders integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.worker_documents (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.health_workers(id) on delete cascade,
  document_type text not null check (
    document_type in ('cnic', 'license', 'certificate', 'degree', 'profile_photo', 'other')
  ),
  file_path text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  rejection_reason text,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.service_categories (
  id uuid primary key default gen_random_uuid(),
  name_en text not null,
  name_ur text not null,
  description_en text,
  description_ur text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.worker_services (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.health_workers(id) on delete cascade,
  service_category_id uuid not null references public.service_categories(id) on delete restrict,
  base_price_pkr integer not null check (base_price_pkr >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (worker_id, service_category_id)
);

create table public.locations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  label text not null default 'current',
  address text not null,
  city text not null,
  latitude numeric(10, 7),
  longitude numeric(10, 7),
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.service_requests (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  service_category_id uuid not null references public.service_categories(id) on delete restrict,
  description text not null,
  image_path text,
  location_id uuid not null references public.locations(id) on delete restrict,
  status text not null default 'searching' check (
    status in ('draft', 'searching', 'offered', 'accepted', 'cancelled', 'expired')
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  service_request_id uuid not null references public.service_requests(id) on delete restrict,
  patient_id uuid not null references public.patients(id) on delete restrict,
  worker_id uuid not null references public.health_workers(id) on delete restrict,
  service_category_id uuid not null references public.service_categories(id) on delete restrict,
  quoted_price_pkr integer not null check (quoted_price_pkr >= 0),
  final_price_pkr integer check (final_price_pkr >= 0),
  platform_commission_pkr integer check (platform_commission_pkr >= 0),
  status text not null default 'accepted' check (
    status in ('accepted', 'worker_on_way', 'started', 'completed', 'cancelled', 'disputed')
  ),
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_events (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  actor_user_id uuid references public.profiles(id),
  event_type text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.chats (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  patient_user_id uuid not null references public.profiles(id) on delete cascade,
  worker_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id) on delete cascade,
  message_type text not null check (message_type in ('text', 'image')),
  body text,
  file_path text,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check (body is not null or file_path is not null)
);

create table public.worker_locations (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.health_workers(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  latitude numeric(10, 7) not null,
  longitude numeric(10, 7) not null,
  created_at timestamptz not null default now()
);

create table public.wallets (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null unique references public.health_workers(id) on delete cascade,
  balance_pkr integer not null default 0,
  status text not null default 'active' check (status in ('active', 'frozen')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  type text not null check (type in ('top_up', 'commission_deduction', 'adjustment', 'refund')),
  amount_pkr integer not null check (amount_pkr > 0),
  direction text not null check (direction in ('credit', 'debit')),
  status text not null default 'pending' check (
    status in ('pending', 'approved', 'rejected', 'completed')
  ),
  reference text,
  screenshot_path text,
  order_id uuid references public.orders(id) on delete set null,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  worker_id uuid not null references public.health_workers(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  review_text text,
  created_at timestamptz not null default now()
);

create table public.medical_records (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  worker_id uuid not null references public.health_workers(id) on delete restrict,
  notes text,
  file_path text,
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null check (type in ('order', 'wallet', 'verification', 'system')),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  reported_by uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'rejected')),
  resolved_by uuid references public.profiles(id),
  resolution_notes text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() = 'admin', false);
$$;

create or replace function public.is_order_participant(order_row public.orders)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.patients p
    where p.id = order_row.patient_id
      and p.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.health_workers hw
    where hw.id = order_row.worker_id
      and hw.user_id = auth.uid()
  );
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger patients_set_updated_at
before update on public.patients
for each row execute function public.set_updated_at();

create trigger health_workers_set_updated_at
before update on public.health_workers
for each row execute function public.set_updated_at();

create trigger worker_services_set_updated_at
before update on public.worker_services
for each row execute function public.set_updated_at();

create trigger service_requests_set_updated_at
before update on public.service_requests
for each row execute function public.set_updated_at();

create trigger orders_set_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

create trigger wallets_set_updated_at
before update on public.wallets
for each row execute function public.set_updated_at();

create index profiles_role_idx on public.profiles(role);
create index profiles_phone_idx on public.profiles(phone);
create index patients_user_id_idx on public.patients(user_id);
create index health_workers_user_id_idx on public.health_workers(user_id);
create index health_workers_type_idx on public.health_workers(worker_type);
create index health_workers_city_idx on public.health_workers(city);
create index health_workers_verification_idx on public.health_workers(verification_status);
create index worker_services_worker_idx on public.worker_services(worker_id);
create index worker_services_category_idx on public.worker_services(service_category_id);
create index service_requests_patient_idx on public.service_requests(patient_id);
create index service_requests_status_idx on public.service_requests(status);
create index orders_patient_idx on public.orders(patient_id);
create index orders_worker_idx on public.orders(worker_id);
create index orders_status_idx on public.orders(status);
create index orders_created_at_idx on public.orders(created_at);
create index messages_chat_created_idx on public.messages(chat_id, created_at);
create index wallet_transactions_wallet_created_idx on public.wallet_transactions(wallet_id, created_at);
create index reviews_worker_idx on public.reviews(worker_id);
create index worker_locations_order_created_idx on public.worker_locations(order_id, created_at);

alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.health_workers enable row level security;
alter table public.worker_documents enable row level security;
alter table public.service_categories enable row level security;
alter table public.worker_services enable row level security;
alter table public.locations enable row level security;
alter table public.service_requests enable row level security;
alter table public.orders enable row level security;
alter table public.order_events enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.worker_locations enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.reviews enable row level security;
alter table public.medical_records enable row level security;
alter table public.notifications enable row level security;
alter table public.disputes enable row level security;

create policy "Users can read own profile"
on public.profiles for select
using (id = auth.uid() or public.is_admin());

create policy "Users can insert own profile"
on public.profiles for insert
with check (id = auth.uid());

create policy "Users can update own profile"
on public.profiles for update
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

create policy "Patients can manage own patient record"
on public.patients for all
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy "Approved workers are visible"
on public.health_workers for select
using (
  verification_status = 'approved'
  or user_id = auth.uid()
  or public.is_admin()
);

create policy "Workers can insert own worker record"
on public.health_workers for insert
with check (user_id = auth.uid());

create policy "Workers can update own worker record"
on public.health_workers for update
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy "Workers and admins can view documents"
on public.worker_documents for select
using (
  public.is_admin()
  or exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Workers can upload own documents"
on public.worker_documents for insert
with check (
  exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Admins can update documents"
on public.worker_documents for update
using (public.is_admin())
with check (public.is_admin());

create policy "Active service categories are public"
on public.service_categories for select
using (is_active = true or public.is_admin());

create policy "Admins manage service categories"
on public.service_categories for all
using (public.is_admin())
with check (public.is_admin());

create policy "Visible worker services"
on public.worker_services for select
using (
  is_active = true
  or public.is_admin()
  or exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Workers manage own services"
on public.worker_services for all
using (
  public.is_admin()
  or exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Users manage own locations"
on public.locations for all
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy "Patients manage own service requests"
on public.service_requests for all
using (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
);

create policy "Approved workers can read searching requests"
on public.service_requests for select
using (
  public.is_admin()
  or exists (
    select 1 from public.health_workers hw
    where hw.user_id = auth.uid()
      and hw.verification_status = 'approved'
      and hw.is_available = true
      and status in ('searching', 'offered')
  )
);

create policy "Order participants can read orders"
on public.orders for select
using (public.is_admin() or public.is_order_participant(orders));

create policy "Patients and admins can create orders"
on public.orders for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
);

create policy "Order participants can update orders"
on public.orders for update
using (public.is_admin() or public.is_order_participant(orders))
with check (public.is_admin() or public.is_order_participant(orders));

create policy "Participants can read order events"
on public.order_events for select
using (
  public.is_admin()
  or exists (
    select 1 from public.orders o
    where o.id = order_id and public.is_order_participant(o)
  )
);

create policy "Participants can create order events"
on public.order_events for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.orders o
    where o.id = order_id and public.is_order_participant(o)
  )
);

create policy "Chat participants can read chats"
on public.chats for select
using (
  public.is_admin()
  or patient_user_id = auth.uid()
  or worker_user_id = auth.uid()
);

create policy "Order participants can create chats"
on public.chats for insert
with check (
  public.is_admin()
  or patient_user_id = auth.uid()
  or worker_user_id = auth.uid()
);

create policy "Chat participants can read messages"
on public.messages for select
using (
  public.is_admin()
  or exists (
    select 1 from public.chats c
    where c.id = chat_id
      and (c.patient_user_id = auth.uid() or c.worker_user_id = auth.uid())
  )
);

create policy "Chat participants can send messages"
on public.messages for insert
with check (
  exists (
    select 1 from public.chats c
    where c.id = chat_id
      and (c.patient_user_id = auth.uid() or c.worker_user_id = auth.uid())
  )
  and sender_user_id = auth.uid()
);

create policy "Order participants can read worker locations"
on public.worker_locations for select
using (
  public.is_admin()
  or exists (
    select 1 from public.orders o
    where o.id = order_id and public.is_order_participant(o)
  )
);

create policy "Workers can add own location updates"
on public.worker_locations for insert
with check (
  exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Workers can read own wallet"
on public.wallets for select
using (
  public.is_admin()
  or exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Admins manage wallets"
on public.wallets for all
using (public.is_admin())
with check (public.is_admin());

create policy "Workers can create own wallet"
on public.wallets for insert
with check (
  exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Workers can read own wallet transactions"
on public.wallet_transactions for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.wallets w
    join public.health_workers hw on hw.id = w.worker_id
    where w.id = wallet_id and hw.user_id = auth.uid()
  )
);

create policy "Workers can request wallet top ups"
on public.wallet_transactions for insert
with check (
  type = 'top_up'
  and direction = 'credit'
  and status = 'pending'
  and exists (
    select 1
    from public.wallets w
    join public.health_workers hw on hw.id = w.worker_id
    where w.id = wallet_id and hw.user_id = auth.uid()
  )
);

create policy "Admins update wallet transactions"
on public.wallet_transactions for update
using (public.is_admin())
with check (public.is_admin());

create policy "Order participants can read reviews"
on public.reviews for select
using (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
  or exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Patients can create own reviews"
on public.reviews for insert
with check (
  exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
);

create policy "Patients workers admins read medical records"
on public.medical_records for select
using (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
  or exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Assigned workers can create medical records"
on public.medical_records for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.health_workers hw
    where hw.id = worker_id and hw.user_id = auth.uid()
  )
);

create policy "Users read own notifications"
on public.notifications for select
using (user_id = auth.uid() or public.is_admin());

create policy "Admins create notifications"
on public.notifications for insert
with check (public.is_admin());

create policy "Users update own notifications"
on public.notifications for update
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

create policy "Order participants manage disputes"
on public.disputes for all
using (
  public.is_admin()
  or reported_by = auth.uid()
  or exists (
    select 1 from public.orders o
    where o.id = order_id and public.is_order_participant(o)
  )
)
with check (
  public.is_admin()
  or reported_by = auth.uid()
  or exists (
    select 1 from public.orders o
    where o.id = order_id and public.is_order_participant(o)
  )
);

insert into storage.buckets (id, name, public)
values
  ('profile-photos', 'profile-photos', true),
  ('worker-documents', 'worker-documents', false),
  ('chat-images', 'chat-images', false),
  ('medical-records', 'medical-records', false),
  ('wallet-topups', 'wallet-topups', false)
on conflict (id) do nothing;

create policy "Profile photos are readable"
on storage.objects for select
using (bucket_id = 'profile-photos');

create policy "Authenticated users upload profile photos"
on storage.objects for insert
with check (bucket_id = 'profile-photos' and auth.role() = 'authenticated');

create policy "Private files are admin readable"
on storage.objects for select
using (
  bucket_id in ('worker-documents', 'chat-images', 'medical-records', 'wallet-topups')
  and public.is_admin()
);

create policy "Authenticated users upload private files"
on storage.objects for insert
with check (
  bucket_id in ('worker-documents', 'chat-images', 'medical-records', 'wallet-topups')
  and auth.role() = 'authenticated'
);
