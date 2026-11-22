# Tuneleaf 🌿

**A little Mac app for your Spotify listening.**

Tuneleaf is an early SwiftUI mini-player built for Apple Silicon. It uses [Spotify Soloist](https://developer.spotify.com/documentation/soloist) for native audio playback—no browser window needed.

> **Work in progress:** This is a prototype, not a full Spotify replacement. Real playback and resource usage still need testing with a Spotify account.

## What it can do

- Start and stop a separately downloaded Spotify Soloist player.
- Show the current track and offer play, pause, and skip controls.
- Play a Spotify URI and connect to a running Soloist instance.
- Store your personal Soloist API key in macOS Keychain.

Library browsing, search, artwork, and media keys are not available yet.

## What you'll need

- An Apple Silicon Mac running macOS 13 or later.
- Xcode or Swift 5.9 or later.
- Spotify Premium and your own Spotify Soloist API key.
- [Spotify Soloist](https://developer.spotify.com/documentation/soloist/tutorials/getting-started), downloaded and extracted from Spotify.

## Give it a spin

1. Follow Spotify's [setup guide](https://developer.spotify.com/documentation/soloist/tutorials/getting-started) to get your personal API key and download the Apple Silicon Soloist executable. Keep the key private.
2. Build the Mac app from this folder:

   ```sh
   bash build-app.sh
   ```

3. Open `.build/Tuneleaf.app`. Choose the extracted Soloist executable, enter your key, and select **Save Key**.
4. Select **Start Soloist**. The first time, select **Tuneleaf** in Spotify Connect on a Spotify app on the same network.
5. Start listening through Spotify Connect, or paste a Spotify URI into Tuneleaf.

After pairing, Soloist plays on your Mac without the Spotify desktop app running. Spotify Soloist builds expire after 90 days; download a fresh build from Spotify when needed. Tuneleaf does not download or update it for you.

## A note on privacy

Your key stays in macOS Keychain, but Soloist requires it as a startup argument, which other local processes may be able to see. **Forget** removes the saved key; it does not revoke the key at Spotify. The local Soloist control endpoint has no authentication, so use Tuneleaf only on a trusted Mac.

## Development

Run `swift test` to check the prototype. Spotify Soloist is distributed by Spotify and is not included in this repository. Before expanding or distributing the app, review [Spotify's developer policy](https://developer.spotify.com/policy) and [Soloist documentation](https://developer.spotify.com/documentation/soloist).

## Disclaimer

Tuneleaf is an independent project and is not affiliated with or endorsed by Spotify.
