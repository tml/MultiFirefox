# MultiFirefox Migration Design

**Date:** 2026-05-06
**Goal:** Migrate MultiFirefox from legacy Objective-C/NIB to Swift + SwiftUI, keeping the existing Xcode project (in-place migration). Both a working tool and a learning exercise in modern macOS development.

---

## Context

MultiFirefox is a small macOS launcher utility that lets users run multiple Firefox versions simultaneously, each with its own profile. The original codebase dates from 2008 (Objective-C, manual retain-release, NIB-based UI, macOS 10.6 deployment target). macOS warns that support for the app will end soon.

The app has ~150 lines of real logic across three files. The migration scope is small.

---

## Requirements

- **Features:** All three existing features must work:
  1. Launch Firefox with a selected version and profile
  2. Open Firefox Profile Manager for the selected version
  3. Create a standalone `.app` shortcut on the Desktop for a version+profile pair (currently broken — fixed in this migration)
- **UI style:** Regular window app (not menu bar). Opens, user picks version+profile, launches Firefox, app quits.
- **Distribution:** GitHub releases with code signing and notarization (same as original).
- **Auto-update:** Sparkle 2.x via Swift Package Manager.
- **Minimum macOS:** 13.0 Ventura.
- **Approach:** In-place migration of the existing Xcode project (Option B) — add Swift files alongside ObjC, then remove ObjC files once replaced.

---

## Architecture

Three new Swift files replace four old Objective-C files:

| Old (Objective-C) | New (Swift) | Role |
|---|---|---|
| `MFF.h` + `MFF.m` | `FirefoxManager.swift` | Core logic: scan versions, parse profiles, launch, open profile manager, create app bundle |
| `MainWindow.h` + `MainWindow.m` | `ContentView.swift` | SwiftUI two-column UI |
| `main.m` + `MainMenu.nib` | `MultiFirefoxApp.swift` | SwiftUI `@main` entry point, Sparkle controller |

Supporting files removed: `MultiFirefox_Prefix.pch`, `MainMenu.nib`, `English.lproj/`, old `Sparkle.framework/` folder.

---

## Model Layer: `FirefoxManager`

An `ObservableObject` class. SwiftUI subscribes to its published properties; the UI updates automatically when they change.

```swift
@Published var versions: [String]   // e.g. ["Firefox 115", "Firefox 120"]
@Published var profiles: [String]   // e.g. ["default", "Work", "Testing"]
```

### Version discovery

Scan `/Applications` using `FileManager`. Collect `.app` bundles whose name starts with `firefox` or `minefield` (case-insensitive). Strip the `.app` suffix. Sort alphabetically. Recurse into non-app Firefox directories (to support FFV-style subdirectory installs).

### Profile discovery

Parse `~/Library/Application Support/Firefox/profiles.ini` line by line. Collect all `Name=` values. Put `default` first, sort the rest alphabetically.

### Launch Firefox

Replace `system()` with `Process` to eliminate shell injection risk:

```swift
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
p.arguments = ["-na", "/Applications/\(version).app", "--args", "-no-remote", "-P", profile]
try p.run()
NSApplication.shared.terminate(nil)
```

### Open Profile Manager

Same `Process`/`open` approach with `--profilemanager` argument instead of `-no-remote -P`.

### Create Application

Replace the broken `NSAppleScript` + "AppleScript Editor" approach. Build a minimal `.app` bundle on the Desktop using `FileManager`:

```
~/Desktop/<version>-<profile>.app/
└── Contents/
    ├── Info.plist        (CFBundleExecutable=launcher, CFBundlePackageType=APPL)
    └── MacOS/
        └── launcher      (executable shell script)
```

The `launcher` script:
```bash
#!/bin/bash
open -na "/Applications/<version>.app" --args -no-remote -P "<profile>"
```

Files are written with `String.write(to:atomically:encoding:)`. The launcher is made executable via `Process` running `/bin/chmod +x`.

---

## UI Layer: `ContentView`

Two-column SwiftUI layout, faithful to the original:

- **Left column:** `List` of Firefox versions (from `FirefoxManager.versions`), single selection. Double-clicking a version launches Firefox immediately (same as clicking Launch Firefox).
- **Right column:** `List` of profiles (from `FirefoxManager.profiles`), single selection
- **Auto-selection:** Selecting a version auto-selects the first profile whose name starts with the version name (matching current behavior)
- **Empty state:** If no Firefox versions are found in `/Applications`, both lists are empty and all buttons are disabled. No separate error dialog.
- **Bottom buttons:**
  - **Launch Firefox** (primary, prominent) — calls `FirefoxManager.launch(version:profile:)`
  - **Show Profile Manager** — calls `FirefoxManager.openProfileManager(version:)`; reloads profile list when the MultiFirefox window next becomes active
  - **Create Application** — calls `FirefoxManager.createApplication(version:profile:)`
- **One-profile warning:** If fewer than two profiles exist on launch, show an alert directing the user to open Profile Manager (matching current behavior)
- **Persistence:** Last selected version and profile saved to `UserDefaults`, restored on launch

---

## Entry Point: `MultiFirefoxApp`

Replaces `main.m` and `MainMenu.nib`. Holds the `SPUStandardUpdaterController` for Sparkle and adds a **Check for Updates…** menu item.

`Info.plist` changes:
- Remove `NSMainNibFile` key
- The `SUFeedURL` key stays as-is (already points to the S3 appcast)

---

## Sparkle Integration

- Added via Swift Package Manager (package already added to project)
- `SPUStandardUpdaterController` instantiated in `MultiFirefoxApp.init()`
- **Check for Updates…** added to the app menu via `.commands { CommandGroup(after: .appInfo) { ... } }`
- Old `Sparkle.framework/` folder deleted from repository

---

## Migration Sequence

Each step leaves the project in a buildable state.

1. **Add `FirefoxManager.swift`** — Swift model alongside existing ObjC. Nothing in the UI uses it yet.
2. **Add `MultiFirefoxApp.swift` + `ContentView.swift`** — SwiftUI entry point and two-column UI wired to `FirefoxManager`. Switch `Info.plist` from NIB-based startup to SwiftUI `@main`.
3. **Delete ObjC files** — Remove `main.m`, `MainWindow.h/.m`, `MFF.h/.m`, `MultiFirefox_Prefix.pch`, `MainMenu.nib` from the project.
4. **Wire up Sparkle** — Add `SPUStandardUpdaterController` to `MultiFirefoxApp` and the Check for Updates menu item.
5. **Clean up** — Delete `Sparkle.framework/` from the repo, update `.gitignore` to exclude `.superpowers/`, bump deployment target to 13.0, fix remaining build warnings.

---

## Out of Scope

- App Store distribution (requires sandboxing, which conflicts with launching arbitrary apps from `/Applications`)
- Dark/light mode theming (SwiftUI handles this automatically)
- Any new features beyond the three existing ones
