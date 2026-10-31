# API Gateway contract expected by the app

This is the current client-side contract, not a statement that these routes
already exist on a deployed gateway. Confirm route names, envelope shapes,
authentication, idempotency, and error responses with the service owners before
connecting production.

## Shared rules

- Configure the gateway base URL in `API_BASE_URL`; the client appends the
  paths below.
- JSON responses are expected unless a multipart attachment is being uploaded.
- Authenticated requests send `Authorization: Bearer <accessToken>`.
- Login and social login return a non-empty `accessToken` and an optional
  `refreshToken`.
- IDs in path segments must be URL-safe. The gateway must authenticate and
  authorize every resource independently of client-side UI checks.
- Do not trust client display state for booking, payment, dispute, call, or
  notification decisions.

## Expected endpoints

| Method | Path | Expected response or request |
| --- | --- | --- |
| GET | `/professionals?search=&category=` | JSON array of professionals |
| GET | `/professionals/{id}` | One professional |
| POST | `/auth/login` | `{email, password}` → `{accessToken, refreshToken?}` |
| POST | `/auth/refresh` | `{refreshToken}` → `{accessToken, refreshToken?}` |
| POST | `/auth/register` | `{name, email, password}` |
| POST | `/auth/email-verification` | `{email, code}` |
| POST | `/auth/email-verification/resend` | `{email}` |
| POST | `/auth/password-recovery` | `{email}` |
| POST | `/auth/password-reset` | `{token, password}` |
| POST | `/auth/logout` | Invalidates the current session |
| GET | `/bookings` | JSON array including server-owned `canCancel` and `canReschedule` flags |
| POST | `/bookings` | `{professionalId, service, scheduledAt, location}` → booking with `id` |
| POST | `/bookings/{id}/cancel` | Optional cancellation `reason` |
| POST | `/bookings/{id}/reschedule` | `{scheduledAt}` |
| GET | `/bookings/{id}/tracking` | `BookingTracking` model fields, optional route and distance |
| POST | `/bookings/{id}/checkout` | `{checkoutUrl}` using HTTPS |
| GET | `/bookings/{id}/payment` | `{status}` |
| GET | `/conversations` | JSON array of conversations |
| GET | `/conversations/{id}/messages` | JSON array of messages |
| POST | `/conversations/{id}/messages` | `{body}` → message |
| POST | `/conversations/{id}/attachments` | Multipart field `file` |
| POST | `/calls` | `{bookingId}` → call record |
| POST | `/calls/{id}/end` | Ends the gateway-managed call |
| GET | `/notifications` | JSON array of notifications |
| PATCH | `/notifications/{id}/read` | Marks one notification read |
| GET | `/notifications/preferences` | `{bookingUpdates, messages, marketing}` booleans |
| PATCH | `/notifications/preferences` | Saves those preference booleans |
| GET | `/profile` | Customer profile JSON |
| PATCH | `/profile` | Updates customer profile fields |
| POST | `/bookings/{id}/review` | `{rating, comment}` |
| POST | `/bookings/{id}/dispute` | `{reason, details}` |

The client also supports an optional WebSocket endpoint configured by
`REALTIME_URL`. It sends a `subscribe` event with the `customer` topic and
access token, then expects JSON event objects containing a `conversationId`,
`bookingId`, or notification `title` and `body`. Confirm this handshake and
event format with the realtime service.

## Model fields

- Professional: `id`, `name`, `title`, `category`, `rating`, `reviewCount`,
  `location`, `avatarUrl`, `latitude`, `longitude`, optional `bio` and
  `startingPrice`.
- Booking: `id`, `service`, `professionalName`, `professionalAvatarUrl`,
  `status`, `date`, `time`, `location`, `amount`, `canCancel`, and
  `canReschedule`.
- Tracking: `bookingId`, `status`, `jobStage`, professional and customer
  coordinates, optional `etaMinutes`, `distanceMeters`, and
  `routeCoordinates` as `[longitude, latitude]` pairs.
- Call: `id` and `status`. The gateway owns call routing and any masked
  numbers.

Use standard non-2xx HTTP statuses and a safe machine-readable error body.
Avoid returning tokens, full phone numbers, payment credentials, or sensitive
support data in error messages. The app displays a generic failure message for
most non-auth updates.
