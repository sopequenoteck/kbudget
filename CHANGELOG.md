# Changelog

Based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows [Semantic Versioning](https://semver.org/).

> 🇫🇷 [Version française](CHANGELOG.fr.md)

## [Unreleased]

### Removed

- **Mobile app: local mode removed** (KKS-335): the mobile app no longer works
  without a server. It is now a client of the API, like the web app, and its
  first launch opens the server setup directly. An app that was set up in local
  mode is sent back to the server setup at its next launch, and its local
  database is erased: there is no migration. When the server cannot be reached,
  the app shows a message and a retry button; a read cache shared with the web
  app is planned (KKS-507).

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
