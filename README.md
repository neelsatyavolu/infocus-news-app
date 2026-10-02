# InFocus for iPhone

The public app for **InFocus**, Palo Alto High School's student broadcast network: every InFocus News episode, the stories from [infocusnews.tv](https://infocusnews.tv), livestreamed games and events, and a way to send an announcement for the show.

Bundle ID `com.infocuspaly.news` · SwiftUI · iOS 17+ · no third-party dependencies.

## What's in it

| Tab | What it does |
|---|---|
| **Home** | A LIVE strip while a stream is on, the latest show (tap to play) with the announcements read on it, the newest stories, and a "Submit an announcement" card. |
| **Shows** | Every episode, one season at a time (`InFocus News \| Season N` playlists). A show plays in the app with its announcements underneath. |
| **Stories** | All infocusnews.tv stories with category chips, endless scroll and search by headline or reporter. A story plays its video in the app; bookmark it to save it on the device. |
| **Live** | What's streaming now, upcoming livestreams (games, concerts, ceremonies) and replays. |
| **More** | Submit an announcement, saved stories, settings (alerts for new shows / new stories / going live, System/Light/Dark), links. |

Notifications: the first launch explains the three alerts and only then asks iOS for permission. The device's APNs token is registered with the Portal (no account); tapping an alert opens that show, story or stream.

## Where the data comes from

- **Stories:** the WordPress REST API on infocusnews.tv (`/wp-json/wp/v2/posts`, `categories`, `staff_name` for bylines). The site's firewall rejects non-browser requests, so the app sends a Safari user agent. A story's video isn't in the REST content, so the app reads the first YouTube embed between the headline and the share icons of the story page (`StoryPageParser`).
- **Shows, live, announcements, alerts:** the InFocus Portal's public API (`https://infocuspaly.com/api/public/…`), which reads the InFocus YouTube channel and the show's teleprompter bulletin on the server. The app holds no API keys.
- **Announcement form:** the Portal's existing `POST /api/announcements/submit`.
- **Video:** the YouTube embed player (`youtube-nocookie.com`) in a web view, with "Open in YouTube".

## Layout

```
InFocus/
  App/          entry point, AppDelegate (push), tabs, routing, config
  Design/       brand tokens (DESIGN.md), type, buttons, cards, loading/empty/error states
  Models/       shows, live, stories (WordPress mapping), HTML text, form, push payloads
  Services/     HTTP, Portal + WordPress clients, stores, preferences, push registration
  Features/     Home, Shows, Stories, Saved, Live, Announce, Settings, Player
  Resources/    assets, Lexend + Geist Mono (OFL), entitlements, privacy manifest
InFocusTests/   decoding, HTML/story-page parsing, dates, form validation, push payloads
scripts/        make-assets.swift, asc-profile.mjs, release-ios.sh
```

Design follows the InFocus Design System 2026 (`DESIGN.md` in the InFocus Portal repo): Ink / Mist 20 surfaces, InFocus Green fills with Soft White text, Green on Dark for small marks, Record Red only for the LIVE dot, Lexend for text and Geist Mono for data, square plates with a 4px green strip, 6px radius on everyday UI, no gradients or shadows.

## Build and test

```bash
brew install xcodegen
xcodegen generate          # writes InFocus.xcodeproj and InFocus/Info.plist (both ignored)
open InFocus.xcodeproj

# command line (use the release Xcode, not a beta)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project InFocus.xcodeproj -scheme InFocus \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test CODE_SIGNING_ALLOWED=NO
```

Debug-only launch arguments: `-InFocusPortalURL http://127.0.0.1:3000` (a local Portal), `-InFocusTab shows|stories|live|more`, `-InFocusOpen story:<id>|show:<videoId>|live:<videoId>`.

Regenerate the icon and wordmarks from the InFocus 2026 Package: `swift scripts/make-assets.swift "<…>/InFocus 2026 Package/01 Logos"`.

## Release to TestFlight

```bash
scripts/release-ios.sh              # archive, sign, upload
scripts/release-ios.sh --no-upload  # archive, sign, export build/InFocus.ipa
```

Credentials come from 1Password only (the Apple Distribution certificate and the team's App Store Connect API key). Put your 1Password account in the gitignored `scripts/release.env` (`INFOCUS_OP_ACCOUNT=…`) first; `scripts/asc-profile.mjs` keeps the "InFocus News App Store" profile current and turns on Push Notifications for the App ID. The App Store Connect app record must exist before the first upload. Listing copy, privacy answers and review notes are in [APP_STORE.md](APP_STORE.md).

## License

MIT. Lexend and Geist Mono are under the SIL Open Font License (see `InFocus/Resources/Fonts`). The InFocus name and logo belong to InFocus / Palo Alto High School.
