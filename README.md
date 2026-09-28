# BrandVault Frontend

Flutter web app for managing a brand profile and asset library.

## Features

- Sign up / sign in, or continue as demo
- Brand kit with color and logo preview
- Folders with nesting
- Asset search, sort, trash, and restore
- AI-generated tags per asset

## Prerequisites

- Flutter 3.19+

## Setup

```bash
flutter pub get
```

## Run Locally

```bash
flutter run -d chrome
```

App opens in browser automatically and connects to backend at `http://localhost:6000`.

To run with mock data (no backend needed):
Edit `lib/core/network/api_client.dart` and set `useMock = true`

## Build for Production

```bash
flutter build web --release
```

Output is in `build/web`.

## Folder Structure

```
lib/
├── core/
│   ├── di/              # Service locator setup
│   ├── network/         # API client, endpoints
│   └── theme/           # App theme and colors
├── features/
│   ├── auth/            # Login, signup
│   ├── brand_kit/       # Brand profile
│   └── asset_library/   # Assets, folders, trash
└── main.dart
```

## Demo Account

Email: `demo@brandvault.dev`  
Password: `Demo1234!`