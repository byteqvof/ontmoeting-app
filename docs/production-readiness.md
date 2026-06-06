# Production Readiness

This checklist keeps dev/test data separated from production and makes release
steps repeatable.

## Environments

Use compile-time configuration for every run:

```powershell
fvm flutter run `
  --dart-define=TOCH_ENV=dev `
  --dart-define=SUPABASE_URL=https://pmnymluxikcmqehlbxlt.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_q9O8Q1jmRZ-9PVGdj_9dYg_S24tTwwt
```

For production, create a separate Supabase project and use its URL/key:

```powershell
fvm flutter build appbundle --release `
  --dart-define=TOCH_ENV=prod `
  --dart-define=SUPABASE_URL=https://<prod-project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<prod-publishable-key> `
  --dart-define=POSTHOG_API_KEY=<posthog-project-key> `
  --dart-define=POSTHOG_HOST=https://eu.i.posthog.com `
  --dart-define=SENTRY_DSN=<sentry-dsn>
```

Never enable `TOCH_FAKE_PHONE_VERIFICATION` outside dev/test. The app ignores
fake phone verification unless `TOCH_ENV=dev`, but release scripts and CI should
also reject it.

## Supabase Deploy

Run this from `meeting-app-backend` after reviewing pending migrations:

```powershell
npx supabase db push --linked --dry-run
npx supabase db lint --linked --schema public,realtime --fail-on error
npx supabase db push --linked
npm run deploy:functions
```

## Security Checks

- RLS enabled on all user data tables.
- `profiles` direct reads only expose own profile; public profile reads go via
  curated Edge Functions/RPCs.
- `activity_chat_messages` access is limited to host and joined participants.
- `realtime.messages` private broadcast access is limited to chat members.
- `content_reports` can only be inserted/read by the reporter.
- `user_blocks` can only be managed/read by the blocker.
- Security definer functions must keep `set search_path = public`.
- Never ship service-role keys in Flutter.

## Safety Operations

The app supports:

- Profile reports through `safety-actions`.
- Activity reports through `safety-actions`.
- User blocks through `safety-actions`.
- Account deletion through `profiles` DELETE; backend deletes the Auth user.
- Moderation queue listing and resolving through `moderation-actions`.

Moderation currently happens in Supabase by reviewing `content_reports`.

## Beta Observability

The Flutter app supports PostHog and Sentry through compile-time config. Keep
analytics privacy-minimal:

- Do not send phone numbers, email addresses, chat text, free report text,
  exact GPS coordinates, or addresses.
- Track funnel, feed, filter, map, activity, join, chat, create, report, and
  block events with IDs/counts/statuses only.
- Use the EU PostHog host for Dutch/EU beta testing.
- Set Sentry `sendDefaultPii=false` and avoid screenshots/session replay.

## Maps

The beta map uses MapLibre with OpenFreeMap public tiles. This is suitable for
testing because it needs no API key and stores no live user locations, but it
does not provide an SLA. Re-evaluate MapTiler/Stadia or another paid tile
provider before a larger public launch.

## Android Release

Before Play Store internal testing:

```powershell
fvm flutter analyze
fvm flutter test
fvm flutter build appbundle --release --dart-define=TOCH_ENV=prod ...
```

Then configure Android signing in `android/key.properties` and
`android/app/build.gradle.kts`, enroll in Play App Signing, and upload the
generated `.aab` to an internal test track.

## Required Before Public Launch

- Privacy policy and support email.
- Terms/community guidelines for meetups and moderation.
- Real SMS provider configured in Supabase Auth.
- PostHog and Sentry project keys configured for beta/prod.
- Supabase paid plan or backup strategy for production data.
- Manual restore drill before real users.
