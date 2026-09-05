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

CI replays all three. The **Tests APP (runner GitHub)** job runs on GitHub's
own infrastructure rather than the private runner — that is the one that gives
a fork's pull request usable feedback.

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

| State | Meaning |
|-------|---------|
| **Tracked** | Parity is maintained |
| **Frozen** | Exists on Flutter, no longer evolves |
| **Never** | Angular only |

**The full classification is still being written down** — the surfaces settled
so far are in the boundary table of
[`docs/architecture.md`](docs/architecture.md).

So: **before porting anything to Flutter, open an issue and ask.** A pull
request that ports a surface intended to stay Angular-only will be declined
however good the code, and neither of us wants that to be discovered after the
work is done.

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
field disappears, or if a request field becomes mandatory. **Error responses
are not covered** — springdoc only documents the 200s — so the contract in
[`docs/api-errors.md`](docs/api-errors.md) still rests on review alone.

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
`app_localizations.dart` is generated by `flutter gen-l10n` yet versioned:
regenerating it silently drops the header.

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
