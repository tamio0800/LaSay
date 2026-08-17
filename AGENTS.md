# Repository Guidelines

## Project Structure & Module Organization

This repository contains the LaSay macOS menu-bar app. The Xcode project is at `VoiceScribe/VoiceScribe.xcodeproj`; application code lives under `VoiceScribe/VoiceScribe/`. Keep SwiftUI screens in `Views/`, transcription and system integrations in `Services/`, persisted state in `Models/`, and focused helpers in `Utilities/`. App icons belong in `Assets.xcassets`; bundled speech models and native `sherpa-onnx` headers/libraries live in `Resources/` and `Libraries/`. XCTest sources are in `VoiceScribe/VoiceScribeTests/`.

## Build, Test, and Development Commands

- `open VoiceScribe/VoiceScribe.xcodeproj` opens the project for normal development.
- `xcodebuild -project VoiceScribe/VoiceScribe.xcodeproj -scheme VoiceScribe -configuration Debug build` performs a command-line debug build.
- `xcodebuild -project VoiceScribe/VoiceScribe.xcodeproj -scheme VoiceScribe clean build` checks a clean build before submission.
- `./package-dmg.sh [beta]` packages an existing Release build; it requires `create-dmg` and expects the app under `VoiceScribe/build/Build/Products/Release/`.

Run XCTest cases with Xcode's Product > Test (`Cmd+U`). The checked-in project currently exposes only the application target, so ensure test files are attached to a test target before relying on CLI test runs.

## Coding Style & Naming Conventions

Use Swift 5 conventions and four-space indentation. Name types in `UpperCamelCase`, methods and properties in `lowerCamelCase`, and test methods as `testExpectedBehavior`. Prefer `final` classes, explicit access control, `guard` for early exits, and `@MainActor` for UI-owned state. Extend existing services and utilities before introducing new layers. No formatter or linter is configured; match nearby code and keep Xcode warnings at zero.

## Testing Guidelines

Tests use XCTest with `@testable import VoiceScribe`. Add focused regression tests beside the existing `*Tests.swift` files. Isolate `UserDefaults`, Keychain, network, and other shared state in setup/teardown so tests remain repeatable. There is no stated coverage threshold; prioritize changed branches and failure paths.

## Commit & Pull Request Guidelines

History generally uses short Conventional Commit prefixes such as `feat:`, `fix:`, `refactor:`, and `chore:`. Keep each commit scoped and imperative. Pull requests should explain user-visible behavior, list verification performed, link relevant issues, and include screenshots for SwiftUI, onboarding, settings, or menu-bar changes. Never commit API keys, credentials, build products, DMGs, logs, or Xcode user data.

Use the GitHub account `tamio0800` for all development, commits, and repository operations. Before committing, verify `gh api user --jq .login` returns `tamio0800` and configure this repository with an email associated with that account.
