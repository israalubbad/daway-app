# feat: patient/pharmacy chat, cart, orders, health profile and new auth API

## What changed

**Chat (patient ↔ pharmacy)**
- One shared chat screen for both sides over the inquiry messages API
  (`/patient|pharmacy/inquiries/{id}/messages`), refreshed by polling every 5 s.
- Conversation lists ("الاستشارات" for patients, "الاستفسارات" for pharmacies):
  one row per pharmacy / per patient, with search and unread counts.
- Images are uploaded to Cloudinary and the link is sent as the message; they
  render without a bubble and open full screen.
- "Which message is mine" prefers `is_mine`, then the sender role, then the
  stored user id, then the shape of the thread.

**Auth**
- Sign-up goes through `POST /register/patient` (age + terms accepted); the
  age is derived from the picked birth date.
- The login response's user id is stored in the session.
- A phone with no account is stopped on the login screen instead of failing
  after the OTP is typed.
- The OTP is shown on the verification screen **temporarily** (SMS is not wired
  up yet) — remove the box in `otp_verification_form.dart` and `tempOtp` later.

**Patient**
- Cart: add item (`pharmacy_medicine_id`), swipe to delete, clear cart.
- Orders: order sheet with cancel.
- Health profile screen + account-hub entry.
- Addresses: label picker (home / work / other), edit sheet, delete.
- Medicine page: availability alert, pharmacy cards with distance beside the
  name, actions pinned to the bottom, category cards open the medicine page.
- Filter is a bottom sheet; home shows the current GPS address; pharmacies map
  has a back button and Arabic-insensitive search.
- Reminders use the device timezone; release proguard rules for notifications.

## Notes
- Google Maps key is read from `android/local.properties` (`MAPS_API_KEY`,
  gitignored).
- New package: `flutter_timezone` (device timezone for scheduled reminders).
- The old single question/reply inquiry screens were replaced by the chat.

## Testing
- `flutter analyze` — only two pre-existing infos.
- `flutter test` — all tests pass.
