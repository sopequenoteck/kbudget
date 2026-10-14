# Changelog

Based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows [Semantic Versioning](https://semver.org/).

> 🇫🇷 [Version française](CHANGELOG.fr.md)

## [Unreleased]

### Added

- **Mobile app: app lock with PIN and biometrics** (KKS-247): the mobile app
  can now be locked. Turn it on in Settings, under "This device": choose a
  4-digit PIN, and optionally unlock with Face ID or fingerprint, the PIN
  remaining the fallback. The app asks for it at launch and after one minute
  away. Five wrong PINs in a row sign you out; "Forgot PIN?" does the same, and
  signing in again with your password is the way back. The lock is turned off
  and the PIN erased whenever the session tokens are erased (sign-out, server
  change), and only then. The PIN is stored salted and hashed in the secure
  storage of the device, never on the server.

### Changed

- **Mobile app: one preferences request at sign-in** (KKS-539): language,
  text size and features each asked the server for the user's preferences
  the moment the session opened, three identical requests at once. Callers
  now share the request in flight; nothing is cached.
- **Mobile app (iOS): iOS 15 is now the minimum version** (KKS-536): Xcode 27
  no longer builds apps that target an earlier version. iPhones and iPads
  limited to iOS 13 or 14 can no longer install the app.

### Removed

- **Mobile app: local mode removed** (KKS-335): the mobile app no longer works
  without a server. It is now a client of the API, like the web app, and its
  first launch opens the server setup directly. An app that was set up in local
  mode is sent back to the server setup at its next launch, and its local
  database is erased: there is no migration. When the server cannot be reached,
  the app shows a message and a retry button; a read cache shared with the web
  app is planned (KKS-507).

### Fixed

- **Mobile app: previous account's name shown on the home screen after
  switching accounts** (KKS-544): the greeting read the stored name once
  and kept it; after signing out and signing in with another account, the
  previous name stayed until a pull-to-refresh or a restart. The name now
  follows the session.
- **Mobile app: features of the previous account kept after switching accounts**
  (KKS-542): enabled features, tab order, notification types and time zone
  were read from the server once, when the app first opened a session, and
  never again. After signing out and signing in with another account, the
  previous account's settings stayed until the app was restarted. They are
  now reloaded at each sign-in.
- **Mobile app: text size chosen on the server ignored until restart** (KKS-538):
  the server preference was read once, at launch, before any sign-in. After
  the first sign-in, or after switching accounts, the device kept its own text
  size until the app was restarted. The preference is now applied at each
  sign-in.
- **Mobile app: first sign-in impossible after the server setup** (KKS-537):
  at first launch, the app kept calling its default address instead of the URL
  that was entered, until it was restarted. Signing in therefore failed for any
  server other than the default one. The entered URL is now used as soon as it
  is confirmed.
- **Mobile app: session lost or black screen when reopening after 15 minutes**
  (KKS-532): when opened with an expired access token, the app could send two
  session renewals at once. The server treats a refresh token used twice as
  stolen and revokes every session of the user, including on the web: sign-in
  screen for an instant, sign-out fifteen minutes later, or a black screen
  until restart. The session is now renewed only once. A wrong current password
  in "Change password" no longer leaves the sheet loading forever.
- **Mobile app: server URL and currencies reachable again** (KKS-418): since
  the settings rewrite, no screen led to the server URL or to the currencies
  and exchange rates. The settings now end with a "Server" section, and the
  accounts screen links to "Currencies & Rates". Saving a new server URL now
  takes effect at once: the app checks that the address is a compatible
  K-Budget server, asks for confirmation, signs you out and returns to the
  sign-in screen. The session tokens of the previous server are erased before
  the switch and are never sent to the new one; previously the new URL only
  applied after a restart, which then sent the old tokens to the new server.

### Security

- **Exception messages no longer carry submitted data** (KKS-500): the
  `message` of a `400 BAD_REQUEST` or `409 CONFLICT` response, which the API
  also writes to its logs, no longer repeats the submitted or financial value:
  bank code, timezone, pattern of a categorisation rule, status of an import
  line, remaining amount of a debt. An unreadable request body or import
  mapping logs only the exception type of the parser. Error codes are
  unchanged; the clients never displayed `message`.
- **Caught exceptions are logged by type, not by message** (KKS-503): when a
  budget threshold check fails after a transaction, a recurring transaction or
  a subscription payment, the API logs the exception type and the category id,
  no longer the message, which a database error can fill with a whole row; same
  for a failed creation of a user's default account or system categories before
  it is reported as a `500`. An unexpected error (`500`) is still logged with
  its full stack trace. An invalid identifier in a URL
  (`/v1/accounts/not-a-uuid`) now returns `400 BAD_REQUEST` instead of `500`,
  and the logs record the parameter name, not the value.

## [6.11.0] - 2026-10-06

> The API logs are now in English and free of personal data, and the account
> deletion dialog says what really happens. No migration, no API contract
> change, `MIN_CLIENT_VERSION` stays at 6.0.0. API, web app and mobile app
> change. First version published as a GitHub Release.

### Added

- **A GitHub Release for every version** (KKS-492): each `vX.Y.Z` tag now
  comes with a GitHub Release whose notes are the version's block of this
  changelog, with the Docker image tags. Nothing to do on your side: the images
  are published before the release is created.

### Changed

- **API logs in English** (KKS-462): every log message is now in English. If
  you filter or alert on log messages, check your patterns.

### Fixed

- **Deleting your profile no longer promises an erasure** (KKS-417): the web
  app announced an irreversible deletion of the account and all its data,
  while the API only deactivates it and keeps the data, and an administrator
  can reactivate it. The dialog, its confirmation box and the settings row now
  say so, and suggest exporting your data first. Same fix for the confirmation
  box of the mobile app.

### Security

- **Logs no longer contain personal data** (KKS-463): e-mail addresses,
  user-entered text (labels, notes, names), third parties' names, imported file
  names, amounts and balances are no longer written to the API logs; users are
  identified by their id, and invitation tokens are no longer logged. Read
  errors of an imported file log only the exception type and the line number.
  The only exceptions are the IP address of a request refused by the rate
  limiter of the authentication endpoints and the first-start banner. Rules for
  contributors in `CONTRIBUTING.md`.

## [6.10.0] - 2026-10-04

> Completes the API side of internationalisation: the API no longer writes
> French text into the data it serves. Migration V43 (two nullable columns on
> import draft lines), additive API contract change only, `MIN_CLIENT_VERSION`
> stays at 6.0.0. Only the API and the web app change. Constitution updated to
> 4.2.0 (documentation).

### Fixed

- **Import read errors in the displayed language** (KKS-441): an unreadable
  statement line showed « Date invalide », « Montant invalide » or « Erreur de
  parsing » in French whatever the language. The API now serves a code
  (`readError`) and the faulty value (`readErrorValue`), which the web app
  translates. API (additive): migration V43, two nullable columns;
  `statusMessage` is still served, in English. Earlier drafts keep their
  original message.
- **Deleting a debt** (KKS-427): the API no longer appends « (dette supprimée -
  …) » to the label of linked repayments; they only lose their link to the
  debt. Labels already modified are left as they are.

## Earlier versions

Versions 6.9.0 and earlier are documented in French only, in
[`CHANGELOG.fr.md`](CHANGELOG.fr.md).

[Unreleased]: https://github.com/sopequenoteck/kbudget/compare/v6.11.0...HEAD
[6.11.0]: https://github.com/sopequenoteck/kbudget/compare/v6.10.0...v6.11.0
[6.10.0]: https://github.com/sopequenoteck/kbudget/compare/v6.9.0...v6.10.0
