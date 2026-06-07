# TOCH Flutter app

Flutter client voor TOCH. De app gebruikt Supabase Edge Functions, Supabase
Realtime, MapLibre/OpenFreeMap en optioneel Firebase Cloud Messaging.

## Snel starten

Installeer dependencies:

```powershell
fvm flutter pub get
```

Start in development mode:

```powershell
.\scripts\run_dev.ps1 -Device emulator-5554
```

Zonder `config/dev.local.json` gebruikt het script `config/dev.example.json`.
Maak lokaal een eigen config wanneer je push, Sentry of PostHog wilt testen:

```powershell
Copy-Item config\dev.example.json config\dev.local.json
```

`config/dev.local.json` wordt niet gecommit.

## Belangrijke dart defines

- `TOCH_ENV`: gebruik `dev` lokaal en `prod` voor productie.
- `TOCH_FAKE_PHONE_VERIFICATION`: alleen actief als `TOCH_ENV=dev`.
- `TOCH_ENABLE_PUSH`: zet FCM-tokenregistratie aan.
- `SUPABASE_URL` en `SUPABASE_ANON_KEY`: Supabase projectconfig.
- `POSTHOG_API_KEY`, `POSTHOG_HOST`, `SENTRY_DSN`: observability.
- `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_APP_ID`,
  `FIREBASE_API_KEY`: Firebase clientconfig.

Voor productie mag fake phone verification nooit aan staan. De code negeert die
flag buiten `TOCH_ENV=dev`, maar controleer buildconfig alsnog expliciet.

## Verificatie

Gebruik voor een beta-check minimaal:

```powershell
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
```

## Push-notificaties

Plaats `google-services.json` alleen in de Android app wanneer je FCM lokaal wilt
testen. Beperk Firebase API keys in Google Cloud waar mogelijk.

Een Firebase service-account private key hoort nooit in deze repo. Sla die alleen
als Supabase secret op aan backendzijde en roteer hem direct als hij ooit in chat,
logs of git terechtkomt.
