#!/bin/bash
# Builds the Windows and macOS downloads on this Mac, then signs, notarizes and staples
# the macOS app with your Developer ID. Nothing leaves the machine except the upload to
# Apple's notary service, and your signing key never leaves your keychain.
#
#   tools/release.sh             build, sign and notarize into build/
#   tools/release.sh --publish   the same, then create the GitHub release for the
#                                version in project.godot
#
# One-time setup:
#   1. Install Godot's export templates (Editor > Manage Export Templates in Godot).
#   2. Have a "Developer ID Application" certificate with its private key in your keychain.
#   3. Save your notarization login in the keychain under the profile name below:
#        xcrun notarytool store-credentials big-o-arcade --apple-id YOU@example.com --team-id TEAMID
#      It asks for an app-specific password and stores it in your keychain, not in this repo.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
PROFILE="${NOTARY_PROFILE:-big-o-arcade}"
APP_NAME="Big-O Arcade"
VERSION="$(grep '^config/version=' project.godot | cut -d'"' -f2)"
OUT="build"
PUBLISH=0
[ "${1:-}" = "--publish" ] && PUBLISH=1

say() { printf '\n==> %s\n' "$1"; }
die() { printf '\nERROR: %s\n' "$1" >&2; exit 1; }

command -v "$GODOT" >/dev/null || die "Godot not found. Set GODOT=/path/to/godot."
GODOT_VERSION="$("$GODOT" --version | cut -d. -f1-3)"
TEMPLATES="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
[ -f "$TEMPLATES/macos.zip" ] || die "Export templates for Godot $GODOT_VERSION are not installed (looked in $TEMPLATES)."

IDENTITY="$(security find-identity -v -p codesigning | grep 'Developer ID Application' | head -n 1 | awk -F'"' '{print $2}')"
[ -n "$IDENTITY" ] || die "No 'Developer ID Application' identity with a private key in your keychain."
xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1 \
	|| die "No notarization profile named '$PROFILE'. Run the store-credentials command at the top of this script."

say "Building Big-O Arcade $VERSION with Godot $GODOT_VERSION"
rm -rf "./$OUT"
mkdir -p "$OUT/windows" "$OUT/macos"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

say "Exporting Windows"
"$GODOT" --headless --path . --export-release "Windows" "$OUT/windows/BigOArcade.exe" >"$OUT/export-windows.log" 2>&1 \
	|| die "Windows export failed. See $OUT/export-windows.log"
[ -s "$OUT/windows/BigOArcade.exe" ] || die "Windows export produced no file. See $OUT/export-windows.log"

say "Exporting macOS"
"$GODOT" --headless --path . --export-release "macOS" "$OUT/macos/exported.zip" >"$OUT/export-macos.log" 2>&1 \
	|| die "macOS export failed. See $OUT/export-macos.log"
[ -s "$OUT/macos/exported.zip" ] || die "macOS export produced no file. See $OUT/export-macos.log"
ditto -x -k "$OUT/macos/exported.zip" "$OUT/macos"
APP="$OUT/macos/$APP_NAME.app"
[ -d "$APP" ] || die "Expected $APP inside the exported zip."

say "Signing with your Developer ID (macOS may ask to use the key: choose Always Allow)"
# Hardened runtime and a secure timestamp are both required for notarization.
codesign --force --deep --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"

say "Sending to Apple for notarization (usually a few minutes)"
ditto -c -k --keepParent "$APP" "$OUT/macos/notarize.zip"
xcrun notarytool submit "$OUT/macos/notarize.zip" --keychain-profile "$PROFILE" --wait --timeout 30m | tee "$OUT/notary.log"
if ! grep -q "status: Accepted" "$OUT/notary.log"; then
	SUBMISSION="$(grep -m1 '^ *id:' "$OUT/notary.log" | awk '{print $2}')"
	[ -n "$SUBMISSION" ] && xcrun notarytool log "$SUBMISSION" --keychain-profile "$PROFILE" || true
	die "Apple did not accept the build."
fi

say "Stapling the ticket and checking with Gatekeeper"
xcrun stapler staple "$APP"
spctl --assess --type execute "$APP" || die "Gatekeeper still rejects the app."

say "Packaging"
ditto -c -k --keepParent "$APP" "$OUT/BigOArcade-macOS.zip"
cp LICENSE "$OUT/windows/LICENSE.txt"
(cd "$OUT/windows" && zip -q ../BigOArcade-Windows.zip BigOArcade.exe LICENSE.txt)
rm -f "$OUT/macos/notarize.zip" "$OUT/macos/exported.zip"
ls -lh "$OUT"/*.zip

if [ "$PUBLISH" = "1" ]; then
	[ -z "$(git status --porcelain)" ] || die "Commit or stash your changes before publishing."
	say "Publishing v$VERSION to GitHub"
	gh release create "v$VERSION" "$OUT/BigOArcade-Windows.zip" "$OUT/BigOArcade-macOS.zip" \
		--title "Big-O Arcade v$VERSION" --notes-file .github/RELEASE_NOTES.md
else
	say "Done. The signed builds are in $OUT/. Run again with --publish to release v$VERSION."
fi
