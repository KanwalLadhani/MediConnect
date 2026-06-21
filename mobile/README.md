# MediConnect Mobile

Flutter scaffold for the patient and health worker mobile app.

## Current Flow

- Landing screen
- Role selection
- Login/register screens
- Patient onboarding
- Health worker onboarding
- Verification pending screen
- Early patient and worker dashboards

## Run

Once Flutter responds on this machine:

```powershell
flutter pub get
flutter run --dart-define=SUPABASE_URL=your-url --dart-define=SUPABASE_ANON_KEY=your-key
```

## Android Release Readiness

The Android app id is `com.mediconnect.app` and the launcher label is `MediConnect`.

Release builds read signing values from `android/key.properties` when that file exists. Use `android/key.properties.example` as the template and keep the real keystore plus `key.properties` local only.

```properties
storePassword=replace-with-keystore-password
keyPassword=replace-with-key-password
keyAlias=upload
storeFile=upload-keystore.jks
```

## Notes

- Supabase is optional at startup so the UI can render before environment keys are configured.
- Auth and profile repositories are in `lib/services`.
- English and Urdu localization placeholders are in `lib/l10n`.
