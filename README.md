<p align="center"><img src="assets/icon.png" alt="Veritone logo" width="128" /></p>

<h1 align="center">Veritone</h1>
<p align="center">
  A private, local-first macOS transcription app built with SwiftUI, global shortcuts, and pluggable speech-to-text providers.
</p>

<p align="center">
  Completely free. Doesn't require subscriptions or mandatory cloud account, can run fully on your machine.
</p>

---

## Overview

Veritone is a native macOS app for turning speech into text with as little friction as possible. It is designed for people who want a clean dictation workflow without being pushed into subscriptions, locked ecosystems, or always-online processing.

You can run it entirely on your own machine with local Whisper models, keep your transcripts private, and still swap to a cloud provider when that makes sense for you. It supports a configurable global shortcut, multiple transcription backends, local model downloads, and automatic transcript delivery through paste and clipboard workflows.

This project is actively in development. The core experience already works, but the goal is to keep refining it into something simpler, faster, and more pleasant to use every day.

## Why This Project Exists

Veritone is being built around a few simple ideas:

- Privacy should be a real option, not a premium feature
- Local inference is genuinely useful, and also just cool
- A good tool does not need a subscription attached to it
- You should be able to choose between on-device models and API-based transcription

The overall product direction was inspired by [OpenWhispr](https://openwhispr.com/), while this project remains its own implementation and is still evolving.

## Highlights

| Feature                   | What it does                                                                         |
| ------------------------- | ------------------------------------------------------------------------------------ |
| Global shortcut recording | Start and stop recording without switching apps                                      |
| Two recording styles      | Choose `Push to Talk` or `Toggle Recording`                                          |
| Transcript delivery modes | Paste into the focused input, copy to clipboard, or both                             |
| Multiple providers        | Use OpenAI Whisper today, local Whisper models on-device, and a future Parakeet slot |
| Local model management    | Download Whisper models directly from the app                                        |
| Free to use               | No subscriptions, no paid unlocks, and no required account                           |
| Native UI                 | Built with SwiftUI for a clean macOS experience                                      |
| Theme support             | Includes a customizable appearance system                                            |

## Provider Support

| Provider        | Status      | Notes                                                     |
| --------------- | ----------- | --------------------------------------------------------- |
| OpenAI Whisper  | Ready       | Uses the OpenAI Audio Transcriptions API with `whisper-1` |
| Local Whisper   | Ready       | Uses WhisperKit with downloadable on-device models        |
| NVIDIA Parakeet | Placeholder | Reserved for future NeMo / NVIDIA-backed integration      |

## How It Works

1. Launch the app and open `Settings`.
2. Pick a transcription provider.
3. If using OpenAI, enter your API key or set `OPENAI_API_KEY`.
4. If using Local Whisper, choose a model and download it.
5. Use the global shortcut to start recording.
6. Stop recording and let Veritone transcribe the result.
7. The transcript is pasted into the focused input, copied to the clipboard, or both, depending on your delivery mode.

## Quick Start

Veritone is currently a development-stage project, but it is already usable and completely free to run.

### Requirements

- macOS
- Xcode
- Swift Package Manager dependencies resolved through the project

### Run Locally

```bash
git clone <your-repo-url>
cd Veritone
open Veritone.xcodeproj
```

Then:

1. Build and run the `Veritone` scheme in Xcode.
2. Open `Settings` inside the app.
3. Configure your preferred provider.
4. Grant permissions when prompted.

## Configuration

### OpenAI Whisper

Veritone can use the OpenAI transcription API. Add it in the app's Settings screen

### Local Whisper

Local transcription is powered by WhisperKit. If you want the most private setup, this is the mode to use. Your audio can stay on your machine from start to finish.

Available model options currently include:

- `Whisper Small (Multilingual)`
- `Whisper Medium (Multilingual)`
- `Whisper Large (Multilingual)`

Models are downloaded from within the app and cached locally for reuse.

## Permissions

Veritone may request the following macOS permissions:

- `Microphone`: required to capture audio for transcription
- `Accessibility`: required to paste transcripts into other apps automatically

If Accessibility access is not available, Veritone falls back to clipboard delivery when needed.

## Default Interaction Model

- Default recording shortcut: `Control + Option + Space`
- `Push to Talk`: hold to record, then release to transcribe
- `Toggle Recording`: press once to start, press again to stop and transcribe
- `Paste and Keep Clipboard`: paste into the focused input and keep the transcript on the clipboard
- `Paste, Copy Only If No Input`: paste when possible, otherwise copy to the clipboard

## Tech Stack

- `SwiftUI` for the app interface
- `Observation` and app state-driven UI updates
- `KeyboardShortcuts` for global shortcut capture
- `WhisperKit` for on-device Whisper inference and model downloads
- `Alamofire` for OpenAI API uploads

## Project Structure

```text
Veritone/
├── Domain/
├── Features/
│   ├── Settings/
│   └── Transcription/
├── Infrastructure/
│   ├── Accessibility/
│   ├── Audio/
│   └── Providers/
├── UI/
└── VeritoneApp.swift
```

## Status

Veritone is still in development, and that is part of the point of this README: this is a real, working project that is actively being shaped. Today it already includes the core transcription loop, provider selection, local model handling, transcript delivery, and manual testing controls.

It is completely free, does not require a subscription, and can already run as a fully local speech-to-text tool on your machine. The provider abstraction also leaves room for additional engines beyond the currently working OpenAI and local Whisper flows.

## Roadmap

- Improve onboarding for first-run setup
- Add richer provider diagnostics and error reporting
- Expand provider integrations beyond the current set
- Add export and transcript history workflows
