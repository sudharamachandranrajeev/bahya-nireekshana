# Security

## Reporting a problem

Please report security problems privately. Don't open a public issue.

1. Open the repository's **Security** tab.
2. Click **Report a vulnerability**.
3. Describe the problem and how to reproduce it.

You get a reply in the same private report.

## What is in scope

- The app on Linux, Windows and Android: the encrypted database, sync, and the updater's checksum
  check.
- The browser extension.
- The Omarchy side:
  - `omarchy/install.sh` and the root helpers it installs (`nireekshana-rules`, `nireekshana-apps`,
    `nireekshana-link-plugin`)
  - the polkit policy
  - the OpenSnitch prompt explainer
- The release workflow and the files it publishes.

## Supported versions

Only the newest release gets fixes.
