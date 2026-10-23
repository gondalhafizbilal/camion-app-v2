# Authentication Update: Email-Only OTP (Twilio SendGrid)

This document summarizes backend changes and the actions required by frontend and mobile clients to migrate from email+phone login (OTP via SMS) to email-only login (OTP via email via Twilio SendGrid).

## Overview
- Login and verification now use email as the sole identifier.
- OTP codes are delivered via email using Twilio SendGrid.
- Previous phone/SMS logic is preserved in comments (not deleted) for reference.
- No database schema changes are required.
- API routes and microservice message patterns are unchanged.

## What changed in the backend
- DTOs (validation)
  - `apps/users-service/src/dto/login.dto.ts`
    - `email: string` remains required.
    - `phone` property and validators are commented out.
  - `apps/users-service/src/dto/verifyOTP.dto.ts`
    - `email: string` and `code: string` are required.
    - `phone` property and validators are commented out.

- Users Service logic
  - `apps/users-service/src/users-service.service.ts`
    - `login(dto)` now requires only `email`.
    - User lookup is by `email` only (previous `{ email, phone }` lookup commented).
    - OTP generation unchanged (6 digits), stored in `user.code`.
    - OTP is sent via email using `EmailService.sendOtp(user.email, OTP)`.
    - Twilio SMS sending via `OTPService.sendSms` is commented.
    - Special user login now checks `SPECIAL_USER_EMAIL` only (phone check commented). When matched, sets `FIXED_OTP`.
    - `verifyOTP(dto, guestId?)` finds user by `email` only; phone checks removed (commented).

- New email sender (Twilio SendGrid)
  - `apps/users-service/src/email.service.ts`: wraps `@sendgrid/mail`.
  - Reads `SENDGRID_API_KEY` and `SENDGRID_FROM_EMAIL` from environment.
  - Simple subject/body template for OTP delivery (HTML + plain text).

- Module wiring
  - `apps/users-service/src/users-service.module.ts`
    - Added `EmailService` to providers. No route/microservice changes.

- Environment variables
  - Added to `.env.example`:
    - `SENDGRID_API_KEY`
    - `SENDGRID_FROM_EMAIL`
  - Existing Twilio SMS envs remain for reference; SMS code paths are commented in service.

## API: Request/Response contracts
- Endpoints (API Gateway) are the same:
  - `POST /users/auth/login` → `{ cmd: 'login_user' }`
  - `POST /users/verify` → `{ cmd: 'verify_user' }`

- Payloads
  - Login request (email-only)
    ```json
    {
      "email": "user@example.com"
    }
    ```
  - Verify request
    ```json
    {
      "email": "user@example.com",
      "code": "123456"
    }
    ```
  - Responses are unchanged in structure (success flags, messages, access token on verify, etc.).

## Special user (for QA/testing)
- Environment-based override allows a fixed OTP for a specific email.
- Set in `.env`:
  - `SPECIAL_USER_EMAIL`
  - `FIXED_OTP` (defaults to `111111` if missing)
- Previous `SPECIAL_USER_PHONE` is no longer used (check commented out).

## Frontend & Mobile: required changes
- Remove phone field from login and verify screens.
- Update form validation:
  - Login: require `email` only.
  - Verify: require `email` and `code`.
- Update API calls:
  - `POST /users/auth/login` body must include only `{ email }`.
  - `POST /users/verify` body must include `{ email, code }`.
- UI/UX updates:
  - Inform the user that OTP will be sent to their email address.
  - Handle potential email delivery delays with appropriate messaging/resend logic.

## DevOps & Configuration
- `.env` additions (already reflected in `.env.example`):
  - `SENDGRID_API_KEY=your-sendgrid-api-key`
  - `SENDGRID_FROM_EMAIL=no-reply@example.com` (must be a verified sender in Twilio SendGrid)
- Ensure the Users Service has access to these envs (docker-compose or deployment platform).

## Testing checklist
1. Set `SENDGRID_API_KEY` and `SENDGRID_FROM_EMAIL` with valid credentials.
2. Register a user or use an existing one with a valid email.
3. Call `POST /users/auth/login` with `{ email }` and verify email is received.
4. Call `POST /users/verify` with `{ email, code }` and expect an access token and user data.
5. Test special user path by setting `SPECIAL_USER_EMAIL` and `FIXED_OTP` and logging in with that email.
6. Confirm that passing `phone` now fails validation (DTOs no longer accept it).

## Rollback
- All removed functionality is preserved via commented code. To restore phone/SMS:
  - Uncomment `phone` fields in DTOs and UsersService, revert queries to `{ email, phone }`, and re-enable `OTPService.sendSms`.

## Files changed
- `apps/users-service/src/dto/login.dto.ts`
- `apps/users-service/src/dto/verifyOTP.dto.ts`
- `apps/users-service/src/users-service.service.ts`
- `apps/users-service/src/email.service.ts` (new)
- `apps/users-service/src/users-service.module.ts`
- `.env.example` (added SendGrid envs)

## Notes
- Registration (`register`) endpoint still accepts phone (unchanged), as requested; only login/verify are email-only now.
- Consider adding rate limiting and OTP expiry if needed.
