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
- `FIREBASE_PROJECT_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_API_KEY`:
  gedeelde Firebase clientconfig.
- `FIREBASE_ANDROID_APP_ID`, `FIREBASE_IOS_APP_ID`: platform-specifieke
  Firebase app-id. `FIREBASE_APP_ID` blijft alleen als legacy fallback bestaan.
- `FIREBASE_IOS_BUNDLE_ID`: iOS bundle id, standaard `nl.gatoch.toch`.
- `TOCH_PUBLIC_SHARE_BASE_URL`: publieke basis-URL voor deelbare
  activiteitlinks, standaard `https://gatoch.nl`.
- `TOCH_PUBLIC_SHARE_URL_TEMPLATE`: optionele volledige template, bijvoorbeeld
  `https://gatoch.nl/a/{activityId}`. Laat leeg voor `/activities/{id}`.

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
testen. De Android Firebase app moet package `com.toch.app` gebruiken. Beperk
Firebase API keys in Google Cloud waar mogelijk.

Voor Android lokaal moet `config/dev.local.json` minimaal bevatten:

```json
{
  "TOCH_ENABLE_PUSH": true,
  "FIREBASE_PROJECT_ID": "toch-1dcaf",
  "FIREBASE_MESSAGING_SENDER_ID": "724429202361",
  "FIREBASE_ANDROID_APP_ID": "1:724429202361:android:28b9277d3ba5dd0c7f8c68",
  "FIREBASE_API_KEY": "<android/web api key>"
}
```

Voor iOS push moet `nl.gatoch.toch` onder een betaald Apple Developer Program
team vallen. Apple Personal Teams kunnen geen provisioning profile maken met de
Push Notifications capability. Kopieer daarom lokaal:

```powershell
Copy-Item ios\Flutter\Signing.xcconfig.example ios\Flutter\Signing.xcconfig
```

Vul in `ios/Flutter/Signing.xcconfig` de betaalde Apple Team ID in bij
`TOCH_DEVELOPMENT_TEAM`. Controleer daarna in Apple Developer dat App ID
`nl.gatoch.toch` de Push Notifications capability heeft en dat Firebase voor iOS
de juiste APNs key/certificaten gebruikt. Voeg in Firebase ook een iOS app toe
met bundle id `nl.gatoch.toch` en zet de iOS app-id in `FIREBASE_IOS_APP_ID`;
gebruik niet de Android app-id voor TestFlight.

Een Firebase service-account private key hoort nooit in deze repo. Sla die alleen
als Supabase secret op aan backendzijde en roteer hem direct als hij ooit in chat,
logs of git terechtkomt.

## Deelbare activiteitlinks

De app deelt activiteiten als publieke HTTPS-links:

```text
https://gatoch.nl/activities/<activity-id>
```

Die pagina moet op het domein een gewone webpagina met OpenGraph-tags tonen en
mag daarna de app openen via `meetingsapp://activity/<activity-id>`. De backend
bevat hiervoor de Supabase Edge Function `activity-share`; deploy deze publiek:

```powershell
cd C:\Users\Gebruiker\Desktop\toch\meeting-app-backend
npm run deploy:function:activity-share
```

Voor echte app-links zijn daarnaast domeinverificatiebestanden nodig:

- Android: `https://gatoch.nl/.well-known/assetlinks.json` met package
  `com.toch.app` en de SHA-256 fingerprint(s) van je debug/release signing key.
- iOS: `https://gatoch.nl/.well-known/apple-app-site-association` met app id
  `<APPLE_TEAM_ID>.nl.gatoch.toch` en pad `/activities/*`.

Zolang die bestanden nog niet staan, blijft de link klikbaar als webpagina, maar
opent Android/iOS de app niet altijd automatisch.
