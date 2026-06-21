create or replace function public.submit_order_review(
  target_order_id uuid,
  review_rating integer,
  review_body text default null
)
returns public.reviews
language plpgsql
security definer
set search_path = public
as $$
declare
  order_record public.orders;
  review_record public.reviews;
begin
  if review_rating < 1 or review_rating > 5 then
    raise exception 'Rating must be between 1 and 5';
  end if;

  select *
  into order_record
  from public.orders
  where id = target_order_id;

  if order_record.id is null then
    raise exception 'Order not found';
  end if;

  if order_record.status <> 'completed' then
    raise exception 'Only completed orders can be reviewed';
  end if;

  if not exists (
    select 1
    from public.patients p
    where p.id = order_record.patient_id
      and p.user_id = auth.uid()
  ) then
    raise exception 'Only the patient can review this order';
  end if;

  insert into public.reviews (
    order_id,
    patient_id,
    worker_id,
    rating,
    review_text
  )
  values (
    target_order_id,
    order_record.patient_id,
    order_record.worker_id,
    review_rating,
    nullif(trim(review_body), '')
  )
  returning * into review_record;

  update public.health_workers hw
  set
    total_reviews = stats.total_reviews,
    average_rating = stats.average_rating
  from (
    select
      worker_id,
      count(*)::integer as total_reviews,
      round(avg(rating)::numeric, 2) as average_rating
    from public.reviews
    where worker_id = order_record.worker_id
    group by worker_id
  ) stats
  where hw.id = stats.worker_id;

  insert into public.order_events (
    order_id,
    actor_user_id,
    event_type,
    metadata
  )
  values (
    target_order_id,
    auth.uid(),
    'reviewed',
    jsonb_build_object('rating', review_rating)
  );

  return review_record;
end;
$$;

grant execute on function public.submit_order_review(uuid, integer, text) to authenticated;
