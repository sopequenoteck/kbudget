# Changelog

Based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows [Semantic Versioning](https://semver.org/).

> 🇫🇷 [Version française](CHANGELOG.fr.md)

## [Unreleased]

### Fixed

- **Deleting your profile no longer promises an erasure** (KKS-417): the web
  app announced an irreversible deletion of the account and all its data,
  while the API only deactivates it and keeps the data, and an administrator
  can reactivate it. The dialog, its confirmation box and the settings row now
  say so, and suggest exporting your data first. Same fix for the confirmation
  box of the mobile app.

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

[Unreleased]: https://github.com/sopequenoteck/kbudget/compare/v6.10.0...HEAD
[6.10.0]: https://github.com/sopequenoteck/kbudget/compare/v6.9.0...v6.10.0
