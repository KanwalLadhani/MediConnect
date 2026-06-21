insert into storage.buckets (id, name, public)
values ('service-request-images', 'service-request-images', false)
on conflict (id) do nothing;

create policy "Service request images are admin readable"
on storage.objects for select
using (
  bucket_id = 'service-request-images'
  and public.is_admin()
);

create policy "Authenticated users upload service request images"
on storage.objects for insert
with check (
  bucket_id = 'service-request-images'
  and auth.role() = 'authenticated'
);
