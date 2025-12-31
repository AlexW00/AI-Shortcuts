# Privacy Policy — AI Shortcuts

**Effective date:** 2025-12-31

AI Shortcuts is a client app that helps you run Siri Shortcuts (App Intents) that call an AI provider (for example, OpenAI). This policy explains what data the app handles and where it goes.

## Summary

- The app does **not** run its own backend server and does **not** collect analytics or advertising identifiers.
- Apple may collect device diagnostics related to app usage depending on your system settings (for example, if you share crash reports with developers).
- Your requests (prompt text, images, and/or audio you provide) are sent **directly from your device** to the AI endpoint you configure.
- Your API key is stored securely in **Keychain** (optionally synced via **iCloud Keychain** if you enable it).
- Some non-sensitive settings can be synced via **iCloud** (NSUbiquitousKeyValueStore) to keep configuration consistent across your devices.

## Information the app collects or stores

### On your device

- **API key:** Stored in the system Keychain. If iCloud Keychain is enabled on your device, the key may sync across your devices via iCloud Keychain.
- **App settings:** Such as endpoint configuration (host/base path/scheme/port) and default model selections. These are stored locally and may sync via iCloud key-value storage when available.

### Content you send for AI requests

When you run a shortcut action, the app may process:

- Prompt text and optional system prompts
- Images (if you attach images)
- Audio files (for transcription)
- Text for text-to-speech
- Model names and other request parameters required to fulfill the action

The app uses this information only to perform the action you requested.

## Where your data goes (third parties)

AI Shortcuts sends request content to the AI provider endpoint you configure (for example `https://api.openai.com/v1`). That provider will receive the request data you submit and may process it according to their own privacy policy and terms.

If you configure a custom endpoint (such as a self-hosted or third-party provider), your request content will be sent to that endpoint instead.

Separately, when iCloud sync features are enabled, Apple’s iCloud services may store and transmit:

- **Keychain items** (API key) via iCloud Keychain (if enabled)
- **Non-sensitive settings** via iCloud key-value storage (if available)

## Data retention

- The app does not intentionally retain a server-side copy of your prompts, images, or audio because it does not operate a backend.
- Any retention performed by your chosen AI provider is governed by that provider’s policies.

## Security

The app uses system services (Keychain and iCloud) to protect sensitive information like your API key. No method of storage or transmission is 100% secure, but the app is designed to minimize data exposure.

## Children’s privacy

AI Shortcuts is not directed to children. If you believe a child has provided personal information via the app, please contact the developer so it can be addressed.

## Changes to this policy

This policy may be updated from time to time. The latest version in this repository is the current policy.

## Contact

For privacy questions or requests, please open an issue in this repository.
