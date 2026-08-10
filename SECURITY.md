# Security Policy

Stork is an EFB (Electronic Flight Bag) application used in aviation contexts.
We take security seriously, especially given the potential safety implications
of flight-related software.

## Supported Versions

Only the latest release on the `main` branch is actively supported. Security
fixes are applied to the current version and released as soon as possible.

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| older   | :x:                |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Instead, report vulnerabilities privately so they can be addressed before
disclosure. To report a vulnerability:

1. Use the GitHub private vulnerability reporting feature at
   **https://github.com/jobes/stork/security/advisories** (preferred), or
2. Contact the maintainers directly (see the repository profile for contact
   details).

### What to include

To help us triage and fix the issue quickly, please include:

- A description of the vulnerability and its potential impact (e.g., data
  exposure, memory safety, network/DNS spoofing, corrupted telemetry data).
- Steps to reproduce or a minimal proof-of-concept.
- Affected component(s) and version(s).
- Any suggested fix, if you have one.

### What to expect

- We will acknowledge receipt within **7 days**.
- We will keep you informed of the progress towards a fix and release.
- We will credit you in the advisory (unless you prefer to remain anonymous).

We appreciate responsible disclosure and will handle all reports confidentially.

## Security Considerations for This Project

- **Telemetry integrity** — decoded telemetry (DroneCAN, OGN, GDL90, NOTAMs)
  is untrusted input; it is validated and clamped before use.
- **Network data** — data from external services (AUP portals, NOTAM/FAA API,
  OGN, PureTrack) is treated as untrusted; never trust positions or airspace
  geometry without validation.
- **Web platform** — SQLite and `dart:io` APIs are unavailable on Web; all
  IO-only code is guarded and must never break the build on `kIsWeb`.
- **Secrets** — API keys and credentials must never be committed. Use
  environment variables via `flutter_dotenv` (see `.env.example`); `.env` is
  git-ignored.
