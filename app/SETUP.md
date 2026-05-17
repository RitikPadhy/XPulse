# Setup

## Run on iPhone

1. Plug your iPhone into the Mac, unlock it.
2. From this folder:
   ```
   flutter run --release -d iPhone
   ```
3. Wait for "Flutter run key commands" — app is installed.
4. Open XPulse from your home screen.

Use `--release` (not debug). Debug mode is broken on iOS 26 + this Flutter version; release runs standalone, no cable needed after install.

## First-time only

- Install Xcode from the Mac App Store.
- `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- `sudo xcodebuild -runFirstLaunch`
- `brew install cocoapods`
- iPhone: Settings → Privacy & Security → Developer Mode → On → reboot.
- Open `ios/Runner.xcworkspace` in Xcode → Runner target → Signing & Capabilities → check "Automatically manage signing" → add your Apple ID → pick your Personal Team.

## Notes

- Free Apple ID signing = build expires every **7 days**. Plug in and re-run to refresh.
- Edit code → re-run the same command. No hot reload in release mode.
