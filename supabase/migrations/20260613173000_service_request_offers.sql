create table public.service_request_offers (
  id uuid primary key default gen_random_uuid(),
  service_request_id uuid not null references public.service_requests(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  worker_id uuid not null references public.health_workers(id) on delete cascade,
  quoted_price_pkr integer not null check (quoted_price_pkr >= 0),
  status text not null default 'pending' check (
    status in ('pending', 'accepted', 'declined', 'expired', 'cancelled')
  ),
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (service_request_id, worker_id)
);

create trigger service_request_offers_set_updated_at
before update on public.service_request_offers
for each row execute function public.set_updated_at();

create index service_request_offers_request_idx on public.service_request_offers(service_request_id);
create index service_request_offers_worker_status_idx on public.service_request_offers(worker_id, status);
create index service_request_offers_patient_idx on public.service_request_offers(patient_id);

alter table public.service_request_offers enable row level security;

create policy "Patients create own request offers"
on public.service_request_offers for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
);

create policy "Offer participants can read offers"
on public.service_request_offers for select
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

create policy "Workers can respond to own offers"
on public.service_request_offers for update
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

create policy "Assigned workers can create accepted orders"
on public.orders for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.service_request_offers sro
    join public.health_workers hw on hw.id = sro.worker_id
    where sro.service_request_id = orders.service_request_id
      and sro.worker_id = orders.worker_id
      and sro.patient_id = orders.patient_id
      and sro.status = 'accepted'
      and hw.user_id = auth.uid()
  )
);

create policy "Assigned workers can update offered service requests"
on public.service_requests for update
using (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.service_request_offers sro
    join public.health_workers hw on hw.id = sro.worker_id
    where sro.service_request_id = service_requests.id
      and sro.status = 'accepted'
      and hw.user_id = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.patients p
    where p.id = patient_id and p.user_id = auth.uid()
  )
  or exists (
    select 1
    from public.service_request_offers sro
    join public.health_workers hw on hw.id = sro.worker_id
    where sro.service_request_id = service_requests.id
      and sro.status = 'accepted'
      and hw.user_id = auth.uid()
  )
);

create or replace function public.complete_order_with_commission(
  target_order_id uuid,
  final_price integer
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  order_record public.orders;
  commission_amount integer;
  wallet_record public.wallets;
begin
  if final_price < 0 then
    raise exception 'Final price must be greater than or equal to zero';
  end if;

  select *
  into order_record
  from public.orders
  where id = target_order_id;

  if order_record.id is null then
    raise exception 'Order not found';
  end if;

  if not public.is_admin()
    and not exists (
      select 1
      from public.health_workers hw
      where hw.id = order_record.worker_id
        and hw.user_id = auth.uid()
    ) then
    raise exception 'Not allowed to complete this order';
  end if;

  if order_record.status not in ('accepted', 'worker_on_way', 'started') then
    raise exception 'Order cannot be completed from current status';
  end if;

  commission_amount := ceil(final_price * 0.10)::integer;

  update public.orders
  set
    status = 'completed',
    final_price_pkr = final_price,
    platform_commission_pkr = commission_amount,
    completed_at = now()
  where id = target_order_id
  returning * into order_record;

  update public.health_workers
  set total_completed_orders = total_completed_orders + 1
  where id = order_record.worker_id;

  select *
  into wallet_record
  from public.wallets
  where worker_id = order_record.worker_id;

  if wallet_record.id is not null then
    update public.wallets
    set balance_pkr = balance_pkr - commission_amount
    where id = wallet_record.id;

    insert into public.wallet_transactions (
      wallet_id,
      type,
      amount_pkr,
      direction,
      status,
      reference,
      order_id
    )
    values (
      wallet_record.id,
      'commission_deduction',
      commission_amount,
      'debit',
      'completed',
      '10% platform commission',
      target_order_id
    );
  end if;

  insert into public.order_events (
    order_id,
    actor_user_id,
    event_type,
    metadata
  )
  values (
    target_order_id,
    auth.uid(),
    'completed',
    jsonb_build_object(
      'final_price_pkr',
      final_price,
      'platform_commission_pkr',
      commission_amount
    )
  );

  return order_record;
end;
$$;
