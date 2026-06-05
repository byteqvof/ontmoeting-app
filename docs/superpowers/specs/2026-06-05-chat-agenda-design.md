# Chat And Agenda Design

## Goal

Make the existing `Berichten`, `Agenda`, and `Open de chat` controls functional.

## Scope

- Chat is activity-based: every activity has one thread.
- A user may read and send chat messages only when they organize the activity or have joined it.
- Agenda shows two lists for the signed-in user: activities they organize and activities they joined.
- The first version does not include realtime subscriptions, push notifications, or message deletion.

## Backend

- Add `activity_chat_messages` with activity, sender, body, and created timestamp.
- Add RPC helpers for chat access checks, listing messages, sending messages, and listing joined activities.
- Add Edge Functions:
  - `activity-chat` for `GET` messages and `POST` send.
  - `activities-agenda` for hosted and joined activity lists.

## Flutter App

- Add chat message and agenda entities/usecases to the existing home feature.
- Add pages:
  - `ActivityChatPage`
  - `ActivityMessagesPage`
  - `ActivityAgendaPage`
- Wire existing controls:
  - `Open de chat` opens the activity chat when the user is organizer or joined.
  - `Berichten` opens chat-capable activities.
  - `Agenda` opens hosted and joined activities.

## Testing

- Add Flutter tests for chat message parsing and agenda chat list behavior.
- Verify with `flutter test`, `flutter analyze`, and `flutter build apk --debug`.
- Verify backend migrations/functions against the linked Supabase cloud project.
