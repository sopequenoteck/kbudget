## What this PR does

<!-- One or two sentences. The detail belongs in the commits. -->

## API compatibility

Only fill this in if the PR touches the API, its DTOs, a Flyway migration or
client-side parsing. The rules live in
[`docs/api-compatibility.md`](https://github.com/sopequenoteck/kbudget/blob/main/docs/api-compatibility.md).

- [ ] No response field removed or renamed — we add, we do not take away
- [ ] No request field became mandatory
- [ ] No Flyway migration invalidates a response already being served
- [ ] New enum values are tolerated by older clients
- [ ] **If the break is deliberate**: `minClientVersion` raised, migration note
      in the `CHANGELOG`, major version

> One API version is served at a time. Backward compatibility rests on no
> mechanism at all — only on this review.

## Checks

- [ ] Tests pass on the stacks this touches
- [ ] Documentation updated if the behaviour changed
- [ ] Version bumped in **all four** files if this is a release
      (`VERSION`, `api/pom.xml`, `app/package.json`, `flutter/pubspec.yaml`)
