create or replace function public.review_wallet_top_up(
  target_transaction_id uuid,
  approve_top_up boolean
)
returns public.wallet_transactions
language plpgsql
security definer
set search_path = public
as $$
declare
  top_up_record public.wallet_transactions;
begin
  if target_transaction_id is null then
    raise exception 'Missing wallet top-up transaction';
  end if;

  select *
  into top_up_record
  from public.wallet_transactions
  where id = target_transaction_id
    and type = 'top_up'
    and direction = 'credit'
    and status = 'pending'
  for update;

  if top_up_record.id is null then
    raise exception 'Top-up request is no longer pending';
  end if;

  if top_up_record.amount_pkr <= 0 then
    raise exception 'Top-up amount is invalid';
  end if;

  update public.wallet_transactions
  set
    status = case when approve_top_up then 'approved' else 'rejected' end,
    reviewed_by = auth.uid(),
    reviewed_at = now()
  where id = top_up_record.id
  returning * into top_up_record;

  if approve_top_up then
    update public.wallets
    set balance_pkr = balance_pkr + top_up_record.amount_pkr
    where id = top_up_record.wallet_id;

    if not found then
      raise exception 'Worker wallet not found';
    end if;
  end if;

  return top_up_record;
end;
$$;

revoke execute on function public.review_wallet_top_up(uuid, boolean) from public;
revoke execute on function public.review_wallet_top_up(uuid, boolean) from anon;
revoke execute on function public.review_wallet_top_up(uuid, boolean) from authenticated;
grant execute on function public.review_wallet_top_up(uuid, boolean) to service_role;
