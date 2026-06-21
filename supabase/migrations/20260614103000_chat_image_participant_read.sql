create policy "Chat participants can read chat images"
on storage.objects for select
using (
  bucket_id = 'chat-images'
  and exists (
    select 1
    from public.messages m
    join public.chats c on c.id = m.chat_id
    where m.file_path = storage.objects.name
      and (
        c.patient_user_id = auth.uid()
        or c.worker_user_id = auth.uid()
        or public.is_admin()
      )
  )
);
