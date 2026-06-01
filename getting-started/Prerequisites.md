<!-- GPL-3.0; see root LICENSE -->

![Krista Logo](../kristaLogo.png)

**Breadcrumbs:** [Home](../index.md) > [Getting started](README.md) > Prerequisites

# Prerequisites

## Overview

This page lists the minimal prerequisites for building and iterating on a Krista extension locally.

## Development prerequisites

### Java

- Java **21** (or Gradle toolchain configured to provision Java 21)

### Build tooling

- Gradle (prefer using `./gradlew`)

### Access to a Krista environment

- A Krista environment for uploading/smoke testing the built JAR
- Ability to create/edit invokers in the Setup tab

## Knowledge prerequisites

- Familiarity with REST APIs (or the protocol your external system uses)
- Basic understanding of Java HTTP clients and JSON serialization

## Recommended (not required)

- A test account in the external system
- API keys / OAuth credentials prepared for a sandbox
- A way to inspect HTTP traffic (logs or a proxy)

## Next steps

- Follow the [Local development workflow](LocalDevelopmentWorkflow.md)


## License

This documentation is licensed under the GNU General Public License v3.0. See [`LICENSE`](../../LICENSE).
