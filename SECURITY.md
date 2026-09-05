# Security Policy

k-budget handles personal financial data. If you find a vulnerability, please
report it privately — do not open a public issue.

## Reporting a vulnerability

**Use GitHub's private reporting**: go to the
[Security tab](https://github.com/sopequenoteck/kbudget/security/advisories/new)
and open a draft advisory. It is private between you and the maintainer.

If that is unavailable to you, email **sopequeno.tech@gmail.com** with
`[SECURITY]` in the subject line.

Please include what you need to make the issue reproducible: affected component
(`api/`, `app/`, `flutter/`), version or commit, steps to reproduce, and what
an attacker could obtain. A proof of concept helps, but a clear description is
enough — do not sit on a report because you have not written an exploit.

## What to expect

**This project is maintained by one person, in their spare time.** The
following are honest expectations, not a service-level agreement:

| Step | Realistic timeframe |
|------|--------------------|
| Acknowledgement that your report was read | within 7 days |
| Initial assessment (is it a vulnerability, how serious) | within 14 days |
| Fix for a serious issue | as fast as reasonably possible, and you will be told where it stands |
| Fix for a minor issue | folded into a normal release |

If you have not heard back after two weeks, assume the message was missed
rather than ignored, and send a reminder.

Once fixed, the issue is described in `CHANGELOG.md`. **You will be credited by
name unless you ask not to be.**

## Scope

In scope — this repository:

- The API (`api/`), including authentication, authorisation, and the isolation
  of one user's data from another's
- The Angular client (`app/`) and the Flutter client (`flutter/`)
- The deployment material shipped here (`docker-compose.yml`, `deploy/`)

Out of scope:

- **Any instance you do not own.** k-budget is self-hosted; each instance
  belongs to whoever runs it. Do not test against someone else's server.
- Vulnerabilities in third-party dependencies, unless this project uses them in
  a way that makes an otherwise safe library unsafe — report those upstream.
- Findings that require an attacker to already have administrative access to
  the host or the database.

## Things worth knowing before you report

Some behaviour looks like a vulnerability but is a deliberate decision, written
down here so you do not spend time on it:

- **Rate limiting applies per IP address, never per account.** Locking an
  account after repeated failures would let anyone deny service to a user whose
  email they know. See `RateLimitFilter`.
- **`X-Forwarded-For` is only trusted from a proxy listed in
  `TRUSTED_PROXIES`.** If you can spoof the header from an untrusted source,
  that *is* a finding — the trust boundary is the point.
- **Rate-limit counters are in memory** and reset when the instance restarts.
  A restart gives an attacker a window, not a bypass. This is a deliberate
  trade-off: PostgreSQL is the project's only infrastructure dependency.
- **Swagger UI is disabled outside the `dev` profile.** If you find it exposed
  on a default production deployment, that is a finding.

If you are unsure whether something counts, report it. A false positive costs
far less than a missed vulnerability.
