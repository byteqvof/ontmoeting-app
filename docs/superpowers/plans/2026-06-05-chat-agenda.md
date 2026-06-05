# Chat Agenda Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build activity chat and an agenda overview behind the existing app buttons.

**Architecture:** Keep the current clean architecture shape: Supabase Edge Functions in the backend, Flutter data source/repository/usecase additions, and focused stateful pages for UI flows. Chat access is enforced in Postgres RPCs so the app cannot bypass permissions.

**Tech Stack:** Supabase Postgres, Supabase Edge Functions with `@supabase/server`, Flutter, GoRouter, GetIt, dartz, Equatable.

---

### Task 1: Failing Flutter Tests

**Files:**
- Create: `test/activity_chat_message_model_test.dart`
- Create: `test/activity_agenda_test.dart`

- [ ] Write a failing parser test for `ActivityChatMessageModel.fromJson`.
- [ ] Write a failing domain test for `ActivityAgenda.chatActivities`.
- [ ] Run `flutter test test/activity_chat_message_model_test.dart test/activity_agenda_test.dart`.
- [ ] Confirm failure is caused by missing production classes.

### Task 2: Backend Chat And Agenda

**Files:**
- Create: `meeting-app-backend/supabase/migrations/20260605170000_add_activity_chat_and_agenda.sql`
- Create: `meeting-app-backend/supabase/functions/activity-chat/index.ts`
- Create: `meeting-app-backend/supabase/functions/activities-agenda/index.ts`
- Modify: `meeting-app-backend/supabase/functions/_shared/activity-model.ts`
- Modify: `meeting-app-backend/supabase/config.toml`
- Modify: `meeting-app-backend/package.json`

- [ ] Add chat table, indexes, RLS, and security-definer RPCs.
- [ ] Add joined-activity RPC.
- [ ] Add `activity-chat` Edge Function for listing and sending messages.
- [ ] Add `activities-agenda` Edge Function for hosted and joined activities.

### Task 3: Flutter Data And Domain

**Files:**
- Create: chat and agenda entity/model/usecase files under `lib/features/home`.
- Modify: `lib/features/home/data/datasources/home_remote_data_source.dart`
- Modify: `lib/features/home/data/repositories/home_repository_impl.dart`
- Modify: `lib/features/home/domain/repositories/home_repository.dart`
- Modify: `lib/core/config/supabase_config.dart`
- Modify: `lib/core/di/injection_container.dart`

- [ ] Implement the minimal code that makes Task 1 tests pass.
- [ ] Add remote methods for agenda, chat list, and send message.
- [ ] Add repository and usecase methods with existing failure mapping.

### Task 4: Flutter UI Wiring

**Files:**
- Create: `lib/features/home/presentation/pages/activity_chat_page.dart`
- Create: `lib/features/home/presentation/pages/activity_messages_page.dart`
- Create: `lib/features/home/presentation/pages/activity_agenda_page.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/home/presentation/widgets/home_bottom_nav.dart`
- Modify: `lib/features/home/presentation/widgets/activity_detail_action_bar.dart`
- Modify: `lib/features/home/presentation/pages/activity_detail_page.dart`

- [ ] Add routes for messages, agenda, and chat.
- [ ] Wire `Berichten`, `Agenda`, and `Open de chat`.
- [ ] Render loading, empty, error, and retry states.
- [ ] Allow sending non-empty chat messages and appending the returned message.

### Task 5: Verification

- [ ] Run `dart format` on modified Dart files.
- [ ] Run `flutter test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter build apk --debug`.
- [ ] Push Supabase migration and deploy new functions.
- [ ] Verify the live backend with cloud SQL/function calls.
