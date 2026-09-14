## [0.0.1] - Jul 15,2021

- Setup initial client sdk flow

## [0.0.2] - Jul 15,2021

- Updated example

## [0.0.3] - Jul 15,2021

- Fixed multiple Hive adapter registration issue
- Fixed theme background issue
- Resolved pub analysis issues

## [0.0.4] - Jul 15,2021

- Updated build_runner dependency to null safety version

## [0.0.5] - Jul 20,2021

- Added ChatwootChatModal
- Updated README.md

## [0.0.6] - Jul 20,2021

- Fixed received message widget overflow on mobile screens

## [0.0.7] - Jul 22,2021

- Fixed ChatwootChatDialog avatar color
- Fixed ChatwootChatDialog chat bubble overflow

## [0.0.8] - Jul 22,2021

- Update dependencies

## [0.0.9] - Jul 22,2021

- Fixed message sending issues
- Adds development docs

## [0.0.10]

- Restyled `ChatwootChat` for a full-bleed, WhatsApp-inspired look: edge-to-edge chat page (no wasted side padding outside dialogs), `SafeArea` handling, and a header that shows the agent's real name/avatar (derived from message senders) plus an online/busy/offline/typing status subtitle.
- Added `ChatwootChatTheme.headerColor`, `headerForegroundColor` and `headerSubtitleTextStyle` so the chat page header no longer reuses `primaryColor`/white implicitly. Apps that previously relied on `primaryColor` alone to theme the app bar should now also set `headerColor`/`headerForegroundColor` (or, when using `ChatwootChatDialog.show()`, its new `headerColor`/`headerForegroundColor` parameters, which default to `primaryColor` to match the old look).
- Changed default theme palette to a WhatsApp-style look: light green sent bubbles, teal header, beige chat background. Override via `ChatwootChatTheme` to keep the previous blue branding.
- Fixed `onConversationIsOnline`/`onConversationIsOffline` callbacks not being wired up inside `ChatwootChat` (they were previously never triggered by the plain widget, only by `ChatwootChatDialog`).
- Fixed `onConversationStartedTyping`/`onConversationStoppedTyping` callbacks being swapped inside `ChatwootChat`.
- `ChatwootChatDialog.show()` now opens as a full-screen route (`Navigator.push` with `fullscreenDialog: true`) instead of a small floating `Dialog`. It no longer dismisses on tapping outside; use the chat's back button or `Navigator.pop`.
- `ChatwootChat.showUserNames` now defaults to `false` (was `true`): like a WhatsApp 1:1 conversation, the agent's name is already shown once in the header, so it's no longer repeated on every message. Pass `showUserNames: true` to restore the old behavior.
- Added `ChatwootChat.presenceStatus` (`ChatwootPresenceStatus.online`/`busy`/`offline`) to let host apps override the header status text with their own richer agent-availability signal; the SDK only ever derives `online`/`offline` on its own.
- Added `ChatwootChatTheme.backgroundImageSource` for a chat wallpaper image (local file path or `http(s)://` URL), resolved via the new `chatwootBackgroundImageProvider`. A missing local file or failed network load falls back to the flat `backgroundColor`.
