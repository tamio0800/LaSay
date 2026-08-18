# Repository Guidelines

## User Support Reference

For installation, first-run permissions, configuration, and troubleshooting, read [AGENT_GUIDE.md](AGENT_GUIDE.md) before changing code or asking the user to alter macOS settings. It is written for AI agents helping LaSay users. Use [CONTRIBUTING.md](CONTRIBUTING.md) for the public contribution workflow.

## Project Structure & Module Organization

This repository contains the LaSay macOS menu-bar app. The Xcode project is at `LaSay/LaSay.xcodeproj`; application code lives under `LaSay/LaSay/`. Keep SwiftUI screens in `Views/`, transcription and system integrations in `Services/`, persisted state in `Models/`, and focused helpers in `Utilities/`. App icons belong in `Assets.xcassets`; bundled speech models and native `sherpa-onnx` headers/libraries live in `Resources/` and `Libraries/`. XCTest sources are in `LaSay/LaSayTests/`.

## Model Delegation

- The session's primary model owns work that requires substantial reasoning, judgment, planning, architectural decisions, or review, and remains responsible for the final result.
- Delegate execution-heavy implementation, large-scale data collection, repetitive work, and other routine tasks that require limited reasoning to Luna (`gpt-5.6-luna`).
- The primary model decides whether delegation is appropriate. Use `high` reasoning effort for Luna by default, and increase it up to `max` when the task's complexity or risk warrants it.
- For long-running work with a clear objective, validation loop, and verifiable stopping condition, the primary model should use `/goal` when available. The primary model retains ownership of the goal and delegates suitable execution-heavy subwork to Luna under the rules above.
- The primary model must review and integrate Luna's output before presenting or shipping the final result.

## Build, Test, and Development Commands

- `open LaSay/LaSay.xcodeproj` opens the project for normal development.
- `xcodebuild -project LaSay/LaSay.xcodeproj -scheme LaSay -configuration Debug build` performs a command-line debug build.
- `xcodebuild -project LaSay/LaSay.xcodeproj -scheme LaSay test` runs the XCTest suite.
- `xcodebuild -project LaSay/LaSay.xcodeproj -scheme LaSay clean build` checks a clean build before submission.
- `./package-dmg.sh [beta]` packages an existing Release build; it requires `create-dmg` and expects the app under `LaSay/build/Build/Products/Release/`.
- `./release.sh` archives, Developer ID-signs, notarizes, staples, and verifies a DMG at `build/release/`. It requires the `LaSay-notary` keychain profile and Developer ID certificate; override the profile with `NOTARY_PROFILE=...` when needed.

Run XCTest cases with Xcode's Product > Test (`Cmd+U`) or the command above.

## Coding Style & Naming Conventions

Use Swift 5 conventions and four-space indentation. Name types in `UpperCamelCase`, methods and properties in `lowerCamelCase`, and test methods as `testExpectedBehavior`. Prefer `final` classes, explicit access control, `guard` for early exits, and `@MainActor` for UI-owned state. Extend existing services and utilities before introducing new layers. No formatter or linter is configured; match nearby code and keep Xcode warnings at zero.

## Testing Guidelines

Tests use XCTest with `@testable import LaSay`. Add focused regression tests beside the existing `*Tests.swift` files. Isolate `UserDefaults`, Keychain, network, and other shared state in setup/teardown so tests remain repeatable. There is no stated coverage threshold; prioritize changed branches and failure paths.

## Commit & Pull Request Guidelines

History generally uses short Conventional Commit prefixes such as `feat:`, `fix:`, `refactor:`, and `chore:`. Keep each commit scoped and imperative. Pull requests should explain user-visible behavior, list verification performed, link relevant issues, and include screenshots for SwiftUI, onboarding, settings, or menu-bar changes. Never commit API keys, credentials, build products, DMGs, logs, or Xcode user data.

When working on behalf of the repository owner, use the GitHub account `tamio0800` for development, commits, and repository operations. Before committing, verify `gh api user --jq .login` returns `tamio0800` and configure this repository with an email associated with that account. External contributors use their own accounts and submit pull requests from forks.
