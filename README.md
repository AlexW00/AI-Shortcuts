# AI Shortcuts

This app provides Siri Shortcuts to interact with AI.

The app itself provides configuration for the shortcuts; the actual shortcut building blocks are available in the Shortcuts app on iOS / macOS.

This app is compatible with macOS and iOS.

Under the hood, the app uses [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI).

## Shortcuts (App Intents)

These are the actions the app exposes to the Shortcuts app.

### 1. Ask AI

#### **Intent: `Ask AI`**

- **Description:** Sends a prompt (optionally with images) and returns the text response.
- **Input:**
  - `Prompt` (String)
  - `System Prompt` (Optional String)
  - `Model` (Optional String; defaults to the app’s chat default)
  - `Images` (Optional [File], images only, max 20)
- **Output:** `String`

### 2. Generate Image

#### **Intent: `Generate Image`**

- **Description:** Creates an image based on a prompt.
- **Input:**
  - `Prompt` (String)
  - `Model` (Optional String; defaults to the app’s image default)
  - `Size` (Enum: Auto, 1024×1024, 1024×1536, 1536×1024)
- **Output:** `File` (PNG)
- **Note:** Requires the official OpenAI endpoint (or a provider that supports `POST /v1/images/generations`).

### 3. Audio

#### **Intent: `Transcribe Audio`**

- **Description:** Converts an audio file into text using AI transcription.
- **Input:**
  - `Audio File` (File, audio)
  - `Model` (Optional String; defaults to the app’s transcription default)
  - `Language` (Optional String; ISO-639-1 like `en`, empty = auto-detect)
- **Output:** `String` (Transcription)
- **Supported file types:** mp3, mp4, m4a, wav, webm, mpeg/mpga, ogg/oga, flac (defaults to m4a if unknown).
- **Note:** Requires the official OpenAI endpoint (or a provider that supports `POST /v1/audio/transcriptions`).

#### **Intent: `Read Text Aloud` (TTS)**

- **Description:** Generates spoken audio from text input.
- **Input:**
  - `Text` (String)
  - `Model` (Optional String; defaults to the app’s TTS model, falling back to `tts-1`)
  - `Voice` (Enum: Alloy, Echo, Fable, Onyx, Nova, Shimmer)
  - `Speed` (Double; clamped to 0.25–4.0, default 1.0)
- **Output:** `File` (MP3)
- **Note:** Requires the official OpenAI endpoint (or a provider that supports `POST /v1/audio/speech`).

## Config

- **API Key:** Stored securely (Keychain + iCloud Keychain sync).
- **Endpoint Settings:** Host, Base Path, Scheme, Port (leave empty to use `https://api.openai.com/v1`).
  - The app uses relaxed parsing for non-default endpoints (see [MacPaw/OpenAI docs](https://github.com/MacPaw/OpenAI?tab=readme-ov-file#option-1-use-relaxed-parsing-option)).
- **Default Models:** Optional per-feature defaults used when a shortcut action’s `Model` parameter is left empty.

## Local build scripts

This repo includes a small set of scripts to help avoid committing local signing settings.

- One-time (per clone): `./scripts/install-githooks.sh` (enables the `pre-commit` hook to run `./clean.sh` before commits)
- Create local env: `cp .env.example .env`
- Configure signing: `./configure.sh`
- Build + run (macOS): `./build-macos.sh`

^^
