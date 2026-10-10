# Contributing to k-budget

Thank you for your interest in the project.

> 🇫🇷 Ce document n'existe qu'en anglais pour l'instant. Le README est
> disponible [en français](README.fr.md).

## The easiest place to start: bank import profiles

**You do not need to write Java to make this project meaningfully better.**

k-budget imports transactions from CSV exports. Each bank formats those exports
differently, and a *profile* describes how to read one: which columns hold the
date, the label and the amount, how dates are formatted, which lines to skip.

Today the registry ships very few profiles. If your bank is missing, describing
its export format helps everyone who banks there — and you are the person best
placed to do it, because you have the file.

Open an issue or a pull request with an **anonymised** sample: replace real
amounts, labels and account numbers with plausible fake ones. **Never commit a
real bank statement**, not even your own.

## Running the project

You need PostgreSQL 15+, Java 21, Node 22 and — for the mobile app — Flutter
3.27+.

```bash
cp .env.example .env    # set DB_URL, DB_USERNAME, DB_PASSWORD, JWT_SECRET

cd api && mvn spring-boot:run -Dspring-boot.run.profiles=dev
cd app && npm ci && ng serve
cd flutter && flutter run
```

The `prod` profile is the default; `dev` must be activated explicitly.

**Maven must run under Java 21**, the version CI uses. `java -version` can
report 21 while Maven uses another JDK — `JAVA_HOME` decides, so check with
`mvn -version`. A newer JDK breaks JaCoCo instrumentation with an opaque error;
the build fails early with instructions instead.

## Checks before opening a pull request

| Stack | Command |
|-------|---------|
| API | `cd api && mvn verify` |
| Angular | `cd app && npm test && npx ng lint` |
| Flutter | `cd flutter && flutter analyze && flutter test` |

CI replays all three. Three jobs — **Tests API**, **Tests APP** and **Tests
Flutter**, each suffixed *(runner GitHub)* — run on GitHub's own infrastructure,
so a pull request opened from a fork gets a real result without waiting for
anyone. A fourth, **En-tetes de licence MPL**, runs there too.

The Sonar analysis jobs are the exception: the SonarQube server sits on a
private network, so they run on a self-hosted runner that never executes
unapproved code from a fork. **A fork's pull request therefore gets no Quality
Gate** — a maintainer runs it before merging. Nothing is expected of you there.

### Test naming

Tests are named `should_[outcome]_when_[condition]`, across all three stacks:

```java
void should_return_400_when_password_one_char_below_minimum()
```

```dart
should_showValidationError_when_confirmPasswordDoesNotMatch
```

### Sonar

The Quality Gate runs in **Clean as You Code** mode: only new code is assessed,
so pre-existing issues will not block you.

One thing worth knowing for Dart: **the Sonar profile enforces rules that
`analysis_options.yaml` does not**, so a clean `flutter analyze` is not a
guarantee. In particular, new public members need a `///` doc comment, imports
must be sorted alphabetically, and lines stop at 80 characters.

## Where a change belongs

### Angular is the reference client

Every feature is born on Angular. **Flutter has no parity obligation** — this
is a deliberate decision, because paying for parity screen by screen is what
makes a two-client project unsustainable for one maintainer.

Each surface carries one of three states:

| State | Meaning | Surfaces |
|-------|---------|----------|
| **Tracked** | Parity is maintained: a change on Angular is ported to Flutter | Transactions (recurring, transfers), budgets, subscriptions, debts, accounts, categories, dashboard, notifications, profile, settings, sign-in, invitation, first-login reset, version incompatibility screen |
| **Frozen** | Exists on Flutter, works and is maintained (translations, tests, bug fixes), but takes no new feature | Administration, currencies and exchange rates |
| **Never** | Angular only | Statement import, CSV mapping, import profiles and settings, history clean-up, categorisation rules |

Flutter also carries what the web cannot offer or does not need: server setup,
PIN and biometric lock (planned), system notifications. The full table, with
routes and the gaps known today, is in
[`docs/architecture.md`](docs/architecture.md#frontiere-angular--flutter).

What it means for a pull request:

- A feature starts on Angular. On a **Tracked** surface, the Flutter port is
  welcome, in the same pull request or a later one.
- A new feature on a **Frozen** surface is declined on the Flutter side. A bug
  fix is welcome: frozen means it keeps working.
- A pull request that ports a **Never** surface to Flutter will be declined
  however good the code. The same goes for a feature that would exist on
  Flutter only, outside the list above.

A new surface is classified with one question: *will it keep changing?* If it
will and it is complex, it stays on Angular; a stable CRUD screen on one entity
can live on both. For a surface that is not in the table, **open an issue and
ask before writing code**: neither of us wants this to be discovered after the work is
done.

### The constitution comes first

[`.specify/memory/constitution.md`](.specify/memory/constitution.md) is
authoritative over all other documentation, this file included. Its eight
principles frame what is accepted — notably strict per-user data isolation,
simplicity (no CQRS, DDD or Event Sourcing), and the API as the single source
of truth for every client.

Code conventions and build commands are in [`CLAUDE.md`](CLAUDE.md).

### API changes

The project serves **one API version at a time**. The six rules are in
[`docs/api-compatibility.md`](docs/api-compatibility.md), and the
[pull request template](.github/pull_request_template.md) turns them into a
checklist. It is not decorative.

Two of those rules are now enforced by a test. `ApiContractIT` compares the
OpenAPI schema against a versioned snapshot and fails the build if a response
field disappears, or if a request field becomes mandatory.

**That snapshot still covers the 200s only**, because springdoc emits nothing
for error responses. The contract in
[`docs/api-errors.md`](docs/api-errors.md) is guarded by two other tests
instead. `ValidationErrorCodeContractTest` pins the `details[].code` values to
the real DTOs and the real validator — those codes are derived from the name
of the annotation that failed, so they are written nowhere and a change of
constraint would silently rename them. `ExceptionHandlerInventoryTest` keeps a
versioned inventory of the declared handlers, so a new error code cannot reach
clients without showing up in a diff.

### Logging

API logs are written **in English**, with SLF4J `{}` placeholders only: never
string concatenation. Keep the message free of accents and of a trailing
period.

Logs reach whoever runs an instance, and they outlive the request, so they must
not carry personal data:

| Allowed | Never logged |
|---------|--------------|
| Technical identifiers (`userId`, entity ids) | Any text typed by a user: labels, notes, names of subscriptions, accounts, categories or import profiles |
| Enum codes and statuses | The name of a third party (a debt's counterparty) |
| Counters and durations | The name of an imported file |
| Dates | Amounts and balances |
| Technical URL paths, never a path carrying a token or user data (mask it) | E-mail addresses: log the `userId` instead, for the actor and the target of an admin action alike |

A failed login logs no identifier when the e-mail matches no account, and the
`userId` when it does.

One exception: the only IP address ever logged is that of a request refused by
the rate limiter of the authentication endpoints (HTTP 429), so an attack can
be spotted.

```java
log.info("Debt deleted (debtId={}, userId={})", debtId, userId);            // good
log.info("Debt deleted: {} owed by {}", debt.getLibelle(), debt.getPersonne()); // bad
```

Do not log an entity or a DTO either: its `toString()` prints every field. Log
its id.

Exception messages are logged, so **never put user-entered data in an exception
message**. The read errors of an imported file log only the exception type and
the line number, never its message. Likewise, a parsing error of a request body
or of an import mapping logs only the exception type, never the parser
message, which quotes the input.

When catching an exception you did not raise, log its type
(`e.getClass().getSimpleName()`) and the ids involved, never `e.getMessage()`:
a database error message can quote a whole row. A full stack trace
(`log.error("…", e)`) prints that message too: reserve it for a failure that is
a bug to fix, an unexpected error reported as HTTP 500 or a background job that
cannot proceed, never for a routine log.

The first-start banner, which prints the administrator e-mail and the generated
password once, is the only other exception; it is documented in
[`docs/deployment.md`](docs/deployment.md).

### Interface text

Translation keys, string-writing rules and the English–French glossary are in
[`docs/i18n.md`](docs/i18n.md). Read it before adding a key or a translation:
the key structure is a closed list, and some terms are easy to get wrong — a
*recurring transaction* is not a *subscription*, and *lent* is never *loan*.

## Translating k-budget

**Translating needs no code**, only two catalogues. Once a catalogue is
complete, enabling the language takes a few lines of configuration, listed in
the activation checklist; the maintainer can add them. Translation goes through
pull requests: a translation platform (Weblate) is not set up yet, and will be
once a first translator asks for it.

1. **Start from English**, the reference. Copy `app/public/i18n/en.json` to
   `app/public/i18n/xx.json` (Angular, the web client) and
   `flutter/lib/src/localization/app_en.arb` to
   `flutter/lib/src/localization/app_xx.arb` (Flutter, the mobile client), `xx`
   being the language code. In the ARB file, set `"@@locale": "xx"`; the other
   `@…` entries are metadata, left as they are and never translated.
2. **Translate the values, never the keys or the `{placeholders}`.** Follow
   the rules and the glossary of [`docs/i18n.md`](docs/i18n.md): the glossary
   fixes the meaning of each term (*recurring transaction*, *subscription*,
   *lent*…) and is the same for every language.
3. **Regenerate the Flutter files.** Run `cd flutter && flutter gen-l10n`, then
   commit the new `app_localizations_xx.dart` and the updated
   `app_localizations.dart` next to the ARB file. Generation drops the licence
   header of these files: put it back at the top of each (see
   [The two licences](#the-two-licences)), or the header check fails.
4. **A partial translation is welcome.** It can be merged as it is; the
   language is offered to users once a client's catalogue holds 100 % of the
   keys. Each client is enabled on its own, so Angular may come before
   Flutter. The policy and the activation checklist are in
   [Adding a language](docs/i18n.md#adding-a-language).
5. **Ask a second speaker to review** if you can. It is welcome, not required.

French is maintained by the maintainer; a correction to it is still welcome.

The pull request runs the catalogue checks automatically: no key unknown to
English, every key for an enabled language, the same placeholders as the
English message (including inside `plural` and `select`), valid ICU syntax.
Locally, they are part of `cd app && npm test` and `cd flutter && flutter test`.

**A translation is a contribution like code**: it is covered by the
[CLA](#contributor-licence-agreement), signed once with a comment on your first
pull request.

## Contributor Licence Agreement

**Every pull request must be covered by the [CLA](CLA.md).** An automated check
asks for it on your first one: reply to the pull request with

```
I have read the CLA Document and I hereby sign the CLA
```

Nothing to print, nothing to email. You sign once; later contributions are
covered.

### Why this project asks for one

A CLA is sometimes viewed with suspicion, because it lets the maintainer
relicense contributed code. That concern is legitimate and deserves a straight
answer rather than a line in a form.

k-budget is maintained by one person. Two situations make relicensing a
practical need rather than a theoretical one:

- **Store terms change.** `flutter/` is under MPL-2.0 precisely because Apple's
  terms are incompatible with the AGPL — VLC was pulled from the App Store in
  2011 for that reason, and returned only after changing licence. If those
  terms tighten again, the project has to be able to respond.
- **Sustainability.** Keeping open the option of a differently licensed hosted
  offering may be what allows the project to keep existing.

Without a CLA, both doors close permanently the moment the first external
contribution is merged: relicensing would then require the written agreement of
every contributor, including those who have become unreachable.

**In return, the project undertakes** that your contributions will remain
available under an OSI-approved licence. A relicensing may change which one; it
cannot withdraw them from free software. That undertaking is in the
[CLA](CLA.md) itself, not just a promise in this document.

You keep every right to your contributions and remain free to reuse them.

## The two licences

The repository is not under a single licence. Check which one covers what you
are changing:

| Directory | Licence |
|-----------|---------|
| `api/`, `app/` | **AGPL-3.0-only** ([`LICENSE`](LICENSE)) |
| `flutter/` | **MPL-2.0** ([`flutter/LICENSE`](flutter/LICENSE)) |

**Every new source file in `flutter/lib` must carry the MPL header** — MPL is a
per-file copyleft, and a file without the header loses that information the
moment it leaves the repository:

```dart
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
```

A CI job checks this on every pull request, so a missing header fails the build
rather than reaching the repository unnoticed. It exists because
the `app_localizations*.dart` files are generated by `flutter gen-l10n` yet
versioned: regenerating them silently drops the header.

The name "k-budget" and the logo are reserved and covered by neither licence. A
fork is free to exist, under another name.

Some items fall outside both licences — bank logos and the Inter typeface. They
are listed in [`NOTICE`](NOTICE). **Do not add a brand logo without declaring
it there**, and prefer assets whose licence is unambiguous.

## Reporting problems

Security vulnerabilities: read [`SECURITY.md`](SECURITY.md) and report
privately — not in a public issue.

Anything else: **open a GitHub issue.** Three templates are offered — a bug
report, an idea or question, and a bank export format the importer does not
recognise.

Planning lives on Linear, not here. That changes nothing for you: what deserves
a ticket gets one created on the project side, and your issue stays as the
thread of the conversation. You never need a Linear account.

One thing the templates insist on, and this one is on you: **this is a
budgeting app.** Screenshots, logs and exports carry real amounts and real
account numbers. Replace them with plausible fake ones before posting. An issue
can be edited afterwards — the notification email cannot.

By participating, you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
