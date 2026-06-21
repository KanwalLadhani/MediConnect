-- Run this before production launch to remove local/live test accounts.
-- It targets only MediConnect dummy accounts created with the project test pattern.
--
-- Current known test account pattern:
--   worker.demo.*@mediconnect.test
--   patient.demo.*@mediconnect.test
--   worker.demo.*@example.com
--   patient.demo.*@example.com
--   worker.demo.*@gmail.com
--   patient.demo.*@gmail.com
--
-- Deleting auth.users cascades into public.profiles, then into patient/worker
-- records through the existing foreign keys. Orders and service requests use
-- restrict links for traceability, so remove demo-owned flow records first.

delete from public.orders o
where exists (
  select 1
  from public.patients p
  join public.profiles profile on profile.id = p.user_id
  where p.id = o.patient_id
    and (
      profile.email like 'patient.demo.%@mediconnect.test'
      or profile.email like 'patient.demo.%@example.com'
      or profile.email like 'patient.demo.%@gmail.com'
    )
)
or exists (
  select 1
  from public.health_workers hw
  join public.profiles profile on profile.id = hw.user_id
  where hw.id = o.worker_id
    and (
      profile.email like 'worker.demo.%@mediconnect.test'
      or profile.email like 'worker.demo.%@example.com'
      or profile.email like 'worker.demo.%@gmail.com'
    )
);

delete from public.service_requests sr
where exists (
  select 1
  from public.patients p
  join public.profiles profile on profile.id = p.user_id
  where p.id = sr.patient_id
    and (
      profile.email like 'patient.demo.%@mediconnect.test'
      or profile.email like 'patient.demo.%@example.com'
      or profile.email like 'patient.demo.%@gmail.com'
    )
);

delete from auth.users
where email like 'worker.demo.%@mediconnect.test'
   or email like 'patient.demo.%@mediconnect.test'
   or email like 'worker.demo.%@example.com'
   or email like 'patient.demo.%@example.com'
   or email like 'worker.demo.%@gmail.com'
   or email like 'patient.demo.%@gmail.com';

-- Clean any orphaned demo storage references or manually inserted demo rows
-- if a test was created outside auth.
delete from public.worker_documents
where file_path like 'demo/%';
