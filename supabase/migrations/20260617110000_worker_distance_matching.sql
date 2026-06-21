alter table public.health_workers
  add column if not exists current_latitude numeric(10, 7),
  add column if not exists current_longitude numeric(10, 7),
  add column if not exists current_location_updated_at timestamptz;

create index if not exists health_workers_available_location_idx
on public.health_workers (
  verification_status,
  is_available,
  current_location_updated_at
)
where current_latitude is not null
  and current_longitude is not null;

create or replace function public.find_available_workers_for_request(
  request_category_id uuid,
  request_city text default '',
  request_latitude numeric default null,
  request_longitude numeric default null,
  max_distance_km numeric default 30
)
returns table (
  worker_id uuid,
  user_id uuid,
  full_name text,
  phone text,
  worker_type text,
  city text,
  service_area text,
  base_price_pkr integer,
  average_rating numeric,
  total_reviews integer,
  latitude numeric,
  longitude numeric,
  distance_km double precision,
  eta_minutes integer
)
language sql
stable
security definer
set search_path = public
as $$
  with matched_workers as (
    select
      hw.id as worker_id,
      hw.user_id,
      p.full_name,
      null::text as phone,
      hw.worker_type,
      hw.city,
      hw.service_area,
      ws.base_price_pkr,
      hw.average_rating,
      hw.total_reviews,
      hw.current_latitude as latitude,
      hw.current_longitude as longitude,
      case
        when request_latitude is null or request_longitude is null then null
        when hw.current_latitude is null or hw.current_longitude is null then null
        else (
          6371 * 2 * asin(
            sqrt(
              power(
                sin(radians((hw.current_latitude - request_latitude)::double precision) / 2),
                2
              ) +
              cos(radians(request_latitude::double precision)) *
              cos(radians(hw.current_latitude::double precision)) *
              power(
                sin(radians((hw.current_longitude - request_longitude)::double precision) / 2),
                2
              )
            )
          )
        )
      end as distance_km
    from public.worker_services ws
    join public.health_workers hw on hw.id = ws.worker_id
    join public.profiles p on p.id = hw.user_id
    where exists (
        select 1
        from public.profiles current_profile
        where current_profile.id = auth.uid()
          and current_profile.role = 'patient'
          and current_profile.is_active = true
      )
      and ws.service_category_id = request_category_id
      and ws.is_active = true
      and hw.verification_status = 'approved'
      and hw.is_available = true
      and (
        (
          request_latitude is not null
          and request_longitude is not null
          and hw.current_latitude is not null
          and hw.current_longitude is not null
          and hw.current_location_updated_at >= now() - interval '8 hours'
        )
        or (
          request_latitude is null
          and request_longitude is null
          and lower(trim(hw.city)) = lower(trim(coalesce(request_city, '')))
        )
      )
  )
  select
    matched_workers.worker_id,
    matched_workers.user_id,
    matched_workers.full_name,
    matched_workers.phone,
    matched_workers.worker_type,
    matched_workers.city,
    matched_workers.service_area,
    matched_workers.base_price_pkr,
    matched_workers.average_rating,
    matched_workers.total_reviews,
    matched_workers.latitude,
    matched_workers.longitude,
    matched_workers.distance_km,
    case
      when matched_workers.distance_km is null then null
      else greatest(
        10,
        ceil((matched_workers.distance_km / 22 * 60) + 5)::integer
      )
    end as eta_minutes
  from matched_workers
  where matched_workers.distance_km is null
    or matched_workers.distance_km <= max_distance_km
  order by
    matched_workers.distance_km asc nulls last,
    matched_workers.average_rating desc,
    matched_workers.total_reviews desc;
$$;

grant execute on function public.find_available_workers_for_request(
  uuid,
  text,
  numeric,
  numeric,
  numeric
) to authenticated;
