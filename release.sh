#!/usr/bin/env bash
# Builds, Developer ID-signs, notarizes, staples, and locally verifies LaSay.
# Optional overrides: NOTARY_PROFILE, SIGNING_IDENTITY, RELEASE_DIR.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
team_id="BGRL67W69Y"
identity="${SIGNING_IDENTITY:-Developer ID Application: Bun Pin Tsiu ($team_id)}"
notary_profile="${NOTARY_PROFILE:-LaSay-notary}"
release_dir="${RELEASE_DIR:-$root/build/release}"
workdir="$(mktemp -d "$root/build/release.XXXXXX")"
mountpoint="$workdir/mount"
mounted=0

cleanup() {
  if [[ "$mounted" == 1 ]]; then hdiutil detach "$mountpoint" -quiet || true; fi
  rm -rf "$workdir"
}
trap cleanup EXIT

fail() { printf 'release failed: %s\n' "$*" >&2; exit 1; }
for command in xcodebuild codesign hdiutil xcrun ditto spctl defaults security; do
  command -v "$command" >/dev/null || fail "missing required command: $command"
done
security find-identity -v -p codesigning | grep -Fq "$identity" || fail "Developer ID identity not found: $identity"
xcrun notarytool history --keychain-profile "$notary_profile" --output-format json >/dev/null || fail "notary profile is unavailable: $notary_profile"

archive="$workdir/LaSay.xcarchive"
export_path="$workdir/export"
export_options="$workdir/ExportOptions.plist"

defaults write "$export_options" method -string developer-id
defaults write "$export_options" signingStyle -string manual
defaults write "$export_options" signingCertificate -string 'Developer ID Application'
defaults write "$export_options" teamID -string "$team_id"

echo '==> Archiving Developer ID build'
xcodebuild \
  -project "$root/LaSay/LaSay.xcodeproj" \
  -scheme LaSay \
  -configuration Release \
  -archivePath "$archive" \
  archive \
  CODE_SIGN_STYLE=Manual \
  "CODE_SIGN_IDENTITY=$identity" \
  DEVELOPMENT_TEAM="$team_id" \
  ENABLE_HARDENED_RUNTIME=YES

echo '==> Exporting signed app'
xcodebuild -exportArchive \
  -archivePath "$archive" \
  -exportOptionsPlist "$export_options" \
  -exportPath "$export_path"

app="$export_path/LaSay.app"
[[ -d "$app" ]] || fail "exported app is missing: $app"
codesign --verify --deep --strict --verbose=2 "$app"

version="$(defaults read "$app/Contents/Info" CFBundleShortVersionString)"
build="$(defaults read "$app/Contents/Info" CFBundleVersion)"
mkdir -p "$release_dir"
dmg="$release_dir/LaSay-v$version+$build.dmg"
[[ ! -e "$dmg" ]] || fail "release artifact already exists: $dmg (increment the build number)"

stage="$workdir/dmg-root"
mkdir "$stage"
ditto "$app" "$stage/LaSay.app"
ln -s /Applications "$stage/Applications"

echo '==> Creating and signing DMG'
hdiutil create -volname LaSay -srcfolder "$stage" -format UDZO -ov "$dmg" >/dev/null
codesign --force --sign "$identity" --timestamp "$dmg"
codesign --verify --verbose=2 "$dmg"

echo '==> Submitting DMG for notarization'
xcrun notarytool submit "$dmg" --keychain-profile "$notary_profile" --wait
xcrun stapler staple -v "$dmg"
xcrun stapler validate -v "$dmg"
hdiutil verify "$dmg" >/dev/null
codesign --verify --verbose=2 "$dmg"

echo '==> Verifying installable app'
mkdir "$mountpoint"
hdiutil attach "$dmg" -nobrowse -readonly -mountpoint "$mountpoint" >/dev/null
mounted=1
installed_app="$workdir/installed/LaSay.app"
mkdir -p "$(dirname "$installed_app")"
ditto "$mountpoint/LaSay.app" "$installed_app"
hdiutil detach "$mountpoint" -quiet
mounted=0
codesign --verify --deep --strict --verbose=2 "$installed_app"
spctl --assess --type execute --verbose=4 "$installed_app"

echo '==> Generating Sparkle appcast'
generate_appcast="$({
  find "$HOME/Library/Developer/Xcode/DerivedData" \
    \( \
      -path '*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast' \
      -o -path '*/SourcePackages/checkouts/Sparkle/bin/generate_appcast' \
    \) \
    -type f -perm -111 -print -quit
} 2>/dev/null)"
[[ -n "$generate_appcast" ]] || fail 'Sparkle generate_appcast not found in Xcode SourcePackages'

updates_dir="$workdir/updates"
mkdir "$updates_dir"
ditto "$dmg" "$updates_dir/$(basename "$dmg")"
rm -f "$root/appcast.xml"
"$generate_appcast" \
  --download-url-prefix "https://github.com/tamio0800/LaSay/releases/download/v$version/" \
  --link 'https://github.com/tamio0800/LaSay' \
  -o "$root/appcast.xml" \
  "$updates_dir"

printf '\nRelease verified: %s\n' "$dmg"
