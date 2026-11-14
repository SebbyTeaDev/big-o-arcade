Twelve hands-on levels, a boss round, a step-through code viewer and a cheat sheet for building intuition about data structures, algorithms and Big-O.

## Download

| Platform | File |
|---|---|
| Windows 10 or 11, 64-bit | `BigOArcade-Windows.zip` |
| macOS 11 or later, Apple Silicon and Intel | `BigOArcade-macOS.zip` |

These builds are not code-signed with a paid developer certificate, so both systems warn you the first time.

**Windows**

1. Unzip, then double-click `BigOArcade.exe`.
2. If you see "Windows protected your PC", click **More info**, then **Run anyway**.

**macOS**

1. Unzip, then double-click **Big-O Arcade**.
2. macOS will refuse the first launch. Open **System Settings > Privacy & Security**, scroll down, and click **Open Anyway** next to Big-O Arcade.
3. If macOS says the app is damaged, it has been quarantined by your browser. Clear the flag in Terminal and open it again:

   ```bash
   xattr -dr com.apple.quarantine "Big-O Arcade.app"
   ```

Prefer not to run an unsigned build? Install [Godot 4](https://godotengine.org/download), clone the repository and run `godot --path .` instead.

Progress is saved on your machine. Nothing is sent anywhere.

## Changes

- **1.0.1** fixes a crash that happened every time the game was closed.
- **1.0.0** first release.
