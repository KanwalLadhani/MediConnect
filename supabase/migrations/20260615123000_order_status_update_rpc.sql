create or replace function public.update_order_status_with_event(
  target_order_id uuid,
  target_status text,
  event_metadata jsonb default '{}'::jsonb
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  order_record public.orders;
  updated_order public.orders;
  transition_time timestamptz := now();
  merged_metadata jsonb;
begin
  if target_order_id is null then
    raise exception 'Missing order id';
  end if;

  if target_status = 'completed' then
    raise exception 'Use complete_order_with_commission to complete orders';
  end if;

  if target_status is null
    or target_status not in ('worker_on_way', 'started', 'cancelled') then
    raise exception 'Unsupported order status';
  end if;

  select *
  into order_record
  from public.orders
  where id = target_order_id
  for update;

  if not found then
    raise exception 'Order not found';
  end if;

  if target_status in ('worker_on_way', 'started')
    and not public.is_admin()
    and not exists (
      select 1
      from public.health_workers hw
      where hw.id = order_record.worker_id
        and hw.user_id = auth.uid()
    ) then
    raise exception 'Only the assigned worker can advance this order';
  end if;

  if target_status = 'cancelled'
    and not public.is_admin()
    and not public.is_order_participant(order_record) then
    raise exception 'Only order participants can cancel this order';
  end if;

  if target_status = 'worker_on_way' and order_record.status <> 'accepted' then
    raise exception 'Order cannot move to worker_on_way from current status';
  end if;

  if target_status = 'started' and order_record.status <> 'worker_on_way' then
    raise exception 'Order cannot move to started from current status';
  end if;

  if target_status = 'cancelled'
    and order_record.status not in ('accepted', 'worker_on_way') then
    raise exception 'Order cannot be cancelled from current status';
  end if;

  merged_metadata := coalesce(event_metadata, '{}'::jsonb)
    || jsonb_build_object(
      'previous_status',
      order_record.status,
      'target_status',
      target_status
    );

  update public.orders
  set
    status = target_status,
    started_at = case
      when target_status = 'started' then transition_time
      else started_at
    end,
    cancelled_at = case
      when target_status = 'cancelled' then transition_time
      else cancelled_at
    end
  where id = target_order_id
  returning * into updated_order;

  insert into public.order_events (
    order_id,
    actor_user_id,
    event_type,
    metadata
  )
  values (
    target_order_id,
    auth.uid(),
    target_status,
    merged_metadata
  );

  return updated_order;
end;
$$;

revoke execute on function public.update_order_status_with_event(uuid, text, jsonb) from public;
revoke execute on function public.update_order_status_with_event(uuid, text, jsonb) from anon;
grant execute on function public.update_order_status_with_event(uuid, text, jsonb) to authenticated;
