# Control C

A minimal macOS menu bar clipboard history app.

Lives in the menu bar, captures everything you copy — text, images, files — and lets you paste it back later. No accounts, no sync, no dock icon.

## Features

- **Captures text, images, and files** from the system pasteboard
- **Live thumbnails** via QuickLook (real PNG previews, video frames, PDF pages, etc.)
- **Hover actions** — Preview opens the item in its default app; Copy puts it back on the clipboard
- **Click anywhere on a card** to re-copy
- **Deduplicates** repeated entries and caps history at 50

## Requirements

- macOS 14+ (uses `@Observable` and `MenuBarExtra`)
- Xcode 15+

## Build & install

1. Open `Control C.xcodeproj` in Xcode.
2. **Product → Archive** → in the Organizer, **Distribute App → Custom → Copy App**.
3. Drag `Control C.app` into `/Applications`.
4. First launch: right-click → Open (the app is signed for local development only).
5. Optional: add it to **System Settings → General → Login Items** so it starts with your Mac.

## Project layout

```
Control C/
├── Control_CApp.swift     # MenuBarExtra entry point + AppDelegate
├── ClipboardMonitor.swift # @Observable pasteboard poller
└── ContentView.swift      # Popover UI
```

## How it works

`NSPasteboard` has no change notification, so `ClipboardMonitor` polls `changeCount` every 0.5s on a `Timer`. New content is classified (files first, then images, then text), deduplicated against existing history, and inserted at the top.

`NSApp.setActivationPolicy(.accessory)` (called from the app delegate's `applicationDidFinishLaunching`) hides the dock icon so the app lives only in the menu bar.
