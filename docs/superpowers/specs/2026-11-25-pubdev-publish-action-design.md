# Design: pub.dev publish GitHub Action (short)

## Intent
Publish `lazy_forge` to pub.dev automatically when a version tag is pushed,
with no long-lived secrets (OIDC). Automated publishing is already enabled
on pub.dev by the maintainer (tag pattern `v{{version}}`, no environment).

## Goals
- Pushing tag `vX.Y.Z` runs analyze + tests, then publishes.
- The tag must equal `version` in `pubspec.yaml`; fail early otherwise.

## Non-goals / anti-goals
- No change to `pubspec.yaml` or `CHANGELOG.md` (maintainer decides versions).
- No publishing from branches, PRs or manual dispatch (pub.dev rejects it).
- No new dependencies.

## Constraints
- pub.dev only accepts publishes from a workflow triggered by a tag push.
- Tests live in `tests/` (`dart test tests`); they use temp dirs and never
  start the TUI in the repo.
- Workflow comments in English.

## Approaches
1. Official reusable workflow only: simplest, but no analyze/test gate.
2. Custom workflow (chosen by maintainer): checkout, setup-dart, `dart pub get`,
   version/tag check, `dart analyze`, `dart test tests`, `dart pub publish --force`.
3. Manual dispatch with environment approval: rejected, more setup, no gain.

## Design
`.github/workflows/publish.yml`, trigger `push.tags: 'v[0-9]+.[0-9]+.[0-9]+'`,
one job with `permissions: id-token: write`, `contents: read`, steps as in
approach 2. A README note on the release flow (`git tag vX.Y.Z && git push
origin vX.Y.Z`) is added only if the maintainer wants it.

## Left to the builder
Exact action versions (`actions/checkout`, `dart-lang/setup-dart@v1`).
Recommended follow-up (manual, GitHub settings): tag protection rule for `v*`.
