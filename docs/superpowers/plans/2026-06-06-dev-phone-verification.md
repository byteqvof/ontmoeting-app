# Dev Phone Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a development-only fake phone verification mode so local testers can pass the mandatory phone gate before a real SMS provider is configured.

**Architecture:** Gate the behavior behind `TOCH_ENV=dev` and `TOCH_FAKE_PHONE_VERIFICATION=true`. Keep the fake state local and explicit, while production continues to use Supabase Auth phone verification.

**Tech Stack:** Flutter, Dart compile-time environment flags, SharedPreferences, Supabase Auth, Flutter widget/unit tests.

---

### Task 1: Dev Flag

**Files:**
- Modify: `lib/core/config/supabase_config.dart`
- Test: `test/dev_phone_verification_test.dart`

- [ ] Write tests for `isFakePhoneVerificationAllowed`.
- [ ] Verify the tests fail because the helper does not exist.
- [ ] Add `tochFakePhoneVerificationRequested`, `tochFakePhoneVerificationEnabled`, and `isFakePhoneVerificationAllowed`.
- [ ] Verify the tests pass.

### Task 2: Fake Trust Service

**Files:**
- Modify: `lib/core/services/account_trust_service.dart`
- Modify: `lib/core/di/injection_container.dart`
- Test: `test/dev_phone_verification_test.dart`

- [ ] Write tests for fake request, fake verify, invalid fake token, and production guard.
- [ ] Verify the tests fail because the service does not support fake mode.
- [ ] Inject `SharedPreferences` into `AccountTrustService`.
- [ ] Store fake verification state only when dev fake mode is enabled.
- [ ] Verify the tests pass.

### Task 3: UI Copy

**Files:**
- Modify: `lib/features/profile/presentation/pages/account_gate.dart`

- [ ] Show an explicit development-mode note when fake verification is enabled.
- [ ] In fake mode, show "Ontwikkelcode" instead of "SMS-code".
- [ ] Log and display clearer errors if real Supabase SMS fails.
- [ ] Run analyzer and the full Flutter test suite.
