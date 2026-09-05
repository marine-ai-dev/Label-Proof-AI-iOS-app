# Security Policy

## Reporting a vulnerability

If you discover a security or privacy vulnerability in LabelProof, please
report it privately rather than opening a public GitHub issue:

- Open a [GitHub Security Advisory](../../security/advisories/new) on this
  repository, or
- Contact the maintainers directly (see repository owner profile) with a
  clear description, reproduction steps, and impact assessment.

Please do not disclose the issue publicly until it has been triaged and a
fix (or a statement that no fix is needed) has been released.

## Scope

LabelProof performs no networking and stores all data locally on-device (see
`docs/PRIVACY.md`), so the most relevant classes of issues are:

- Local data handling bugs (e.g. sensitive data unexpectedly persisted,
  unexpected access to camera/photo data).
- Logic errors in the deterministic validation engine that could cause a
  mislabeled package to be reported as PASS.
- Dependency or supply-chain issues (note: this project has zero third-party
  dependencies by design — only Apple system frameworks and the local
  `LabelProofCore` Swift package).

## Supported versions

As a young, actively developed project, only the latest release on `main`
receives security fixes.
