# MediConnect

MediConnect is a Pakistan-focused doorstep healthcare app that lets patients find, hire, chat with, and track verified health workers for basic services at home.

## Current Structure

```text
docs/       Product and technical planning documents
mobile/     Flutter mobile app scaffold
admin/      Next.js admin panel scaffold
supabase/   Database migrations and seed data
```

## Product Direction

- Mobile-first patient and health worker app.
- Admin web panel for verification, orders, wallet top-ups, and disputes.
- Supabase for auth, PostgreSQL, storage, realtime, and edge functions.
- English and Urdu support.
- PKR wallet model with manual JazzCash/EasyPaisa top-up in MVP.

## Setup Notes

The mobile and admin apps are scaffolded and connected to the documented Supabase setup.

```powershell
cd E:\MediConnect\mobile
flutter pub get
flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

For the admin app:

```powershell
cd E:\MediConnect\admin
npm.cmd install
npm.cmd run dev
```

For Supabase, create a project and follow `docs/07-live-supabase-setup.md`.

## Quality Gates

Run these before handoff or deployment packaging:

```powershell
cd E:\MediConnect\mobile
flutter analyze lib test
flutter test --no-pub

cd E:\MediConnect\admin
npm.cmd run test:quality
```

`npm.cmd run test:quality` runs the local readiness preflight, admin unit/static checks, ESLint, and a production Next.js build. It does not create or modify live Supabase data.

Android APK/App Bundle builds require Android Studio or the Android SDK with `ANDROID_HOME` configured. Final release signing uses `mobile/android/key.properties`, which must stay local-only.
