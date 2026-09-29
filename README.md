# BrandVault

Flutter web app for managing a brand kit and an asset library. The API is in [brandvault-backend](<backend-repo-url>).

## Live demo

- App: `https://brandvault-klepon-90763.netlify.app` (the API runs on a free tier and sleeps when idle, so the first load can take up to a minute)
- Demo login: `demo@brandvault.dev` / `Demo1234!`, or click "Continue as demo" on the login page

## Stack

| Layer | Tech |
|---|---|
| App | Flutter (web), Dart |
| Packages | http, shared_preferences, google_fonts |
| API | Node.js, TypeScript, Express |
| Database | PostgreSQL (Supabase) |
| AI | Groq, called from the API only |
| Hosting | Vercel (app), Render (API) |

## Features

- Sign up, sign in and demo login
- Brand kit with name, primary and secondary hex colors, logo URL and font name, plus a live preview and color swatches
- Nested folders (up to 3 levels), search, and sorting by recently updated or name A-Z
- Add assets, move them between folders, trash, restore, and delete permanently from Trash
- AI tag generation with a review step before saving
- Loading, empty and error states on every screen

## Local setup

The app needs the API running. Set it up first using the [backend README](<backend-repo-url>).

```bash
git clone <repo-url>
cd brandvault-frontend
flutter pub get
flutter run -d chrome --web-port=8080 --dart-define=API_BASE_URL=http://localhost:4000 --dart-define=USE_MOCK=false
```

To run the app on built-in sample data without the API:

```bash
flutter run -d chrome --dart-define=USE_MOCK=true
```

| Flag | Purpose |
|---|---|
| `API_BASE_URL` | URL of the API |
| `USE_MOCK` | `true` uses sample data and needs no API |

The backend `CORS_ORIGIN` must match the port the app runs on. `--web-port=8080` matches the default in the backend `.env.example`.

## Production build

```bash
flutter build web --release --dart-define=API_BASE_URL=https://<your-api-url> --dart-define=USE_MOCK=false
```

The output is in `build/web`. Serve it as a static site and send every route to `index.html`.

## Data model

- A user has one brand kit: name, primary color, secondary color, logo URL, font name.
- Folders have a name and an optional `parentId`, up to 3 levels deep.
- Assets have a name, type, URL, optional folder, and optional tags, description and usage suggestion.
- Trashed assets have `deletedAt` set. The library hides them and Trash shows only them.

The models are in `lib/features/*/data/models/`. The database schema and migrations are in the backend repo.

## Authorization

- Every request except sign up and sign in sends a bearer token.
- The token is stored with `shared_preferences`, so a page refresh keeps you signed in.
- If the API returns 401, the app clears the token and goes back to the login screen.
- The API filters every query by the signed-in user and returns 404 for anything that belongs to someone else. Access control is enforced by the API, not by the app.

## GenAI

- Provider: Groq. The model is set by `GROQ_MODEL` on the API.
- Endpoints: `POST /assets/:id/ai-tags` returns a suggestion. `PATCH /assets/:id/ai-tags/save` stores it.
- Input: asset name, type, URL text, folder name, and the brand name and colors when a brand kit exists. The model does not open the file.
- Prompt file: `prompts/asset-tagging.md` in the backend repo
- Validation: the API checks the model's JSON against a schema before it reaches the app. The save endpoint checks the request against the same schema. The app also rejects a response with a missing field.
- Review before save: the suggestion appears in a review card with Save and Discard. Nothing is written until the user presses Save.
- The app holds no AI key. It only knows the API URL.

## Tradeoffs and what I skipped

- Assets are URL records. There is no file upload.
- AI tags come from asset metadata only. The model never opens the file.
- The token is kept in browser storage. It is simple, but scripts on the page can read it. An httpOnly cookie would be safer.
- Folder filtering happens in the app. The API returns all active assets and the app filters by folder.
- Assets move through a dialog. There is no drag and drop.
- There is no folder rename or delete in the UI, although the API supports both.
- There are no Flutter tests. The API has its own test suite and the app was checked by hand.
- Web only. The layout adapts to phone widths, but there is no native mobile build.

## Next improvements

1. Polish the UI: skeleton loaders instead of spinners, a dark mode, consistent icons and spacing, and smoother transitions between screens.
2. Let users edit the AI suggestion (tags, description, usage suggestion) before saving it, not only accept or discard it.
3. File upload for assets and the brand logo.
4. Drag and drop and multi-select for moving or trashing several assets at once, plus folder rename and delete in the UI.
5. Widget and integration tests for sign in, brand kit, trash and restore.

## Project structure

```
lib/
  core/             theme, API client, error handling
  features/
    auth/           sign in, sign up, demo login
    brand_kit/      brand form, preview, summary card
    asset_library/  dashboard, folders, assets, trash, detail panel
  utils/            validators, hex color helpers
  main.dart
```
