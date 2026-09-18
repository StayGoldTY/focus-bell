# Repo Notes

- Default deployment target is GitHub Pages: https://staygoldty.github.io/focus-bell/#/timer
- Build GitHub Pages releases with `flutter build web --release --base-href /focus-bell/`
- Do not add or prefer Vercel or EdgeOne deployment unless the user explicitly asks
- After finishing repository changes, commit and push to `origin/master` unless the user says not to publish

## Cursor Cloud specific instructions

- This is a Flutter web app. The Flutter SDK (stable `3.41.6`, matching `.github/workflows/deploy-github-pages.yml`) is installed at `~/flutter` and added to `PATH` via `~/.bashrc`. In a fresh non-login shell, run `export PATH="$HOME/flutter/bin:$PATH"` first.
- Standard commands (see `README.md`): `flutter pub get`, `flutter analyze` (lint), `flutter test`, `flutter run`.
- To run the app in dev mode for browser testing, use the web-server device: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080` (headless-friendly; then open `http://localhost:8080/`). The Chrome device also works but web-server avoids launching a GUI browser from the CLI.
- First `flutter run`/`flutter test` on a fresh VM downloads the Web SDK and can take 20-40s before the app is served; the blank white page during initial compile is expected — wait and reload.
