# Tuneleaf 🌿

**A small Mac music player.**

Tuneleaf can play an audio file already on your Mac without Spotify or a separate player. Choose **Local Music**, select a file, and use the play, pause, and stop controls. This is a basic player for one local file at a time; it does not play songs from your Spotify library.

**For the separate Spotify prototype, a download is required.** It relies on [Spotify Soloist](https://developer.spotify.com/documentation/soloist), a separate tool from Spotify that plays the music. You need to download it yourself and get an API key before Spotify playback can work. This is a limitation of the current prototype, not the simple, ready-to-use experience I want for the app.

## Why Tuneleaf?

I was using the Spotify app on my MacBook Air M2, but its RAM and CPU usage felt like a lot for a laptop with 8 GB of memory. I wanted a simpler, lighter-feeling way to listen to music on my Mac, so I started building Tuneleaf.

Tuneleaf is still an early prototype. Its resource usage and playback with a Spotify account haven't been fully tested, so there are no performance promises yet.

## Spotify prototype

From a small window, you can:

- See the current track and artist.
- Play, pause, or skip tracks.
- Play a track, album, or playlist using its Spotify URI.

You can also start and stop Soloist from Tuneleaf or connect to a copy that's already running. Library browsing, search, artwork, and media-key controls aren't available yet.

## What you'll need for Spotify

- An Apple Silicon Mac running macOS 13 or later.
- Spotify Premium and a personal Spotify Soloist API key.
- Spotify Soloist, downloaded separately from Spotify.

Tuneleaf is a work in progress, and there isn't a ready-to-download app in this repository yet. You'll currently need to build it yourself. Soloist also expires after 90 days, so you'll need to download a fresh copy from Spotify when that happens.

## Getting connected

Follow Spotify's [Soloist setup guide](https://developer.spotify.com/documentation/soloist/tutorials/getting-started) to get your API key and download Soloist. In Tuneleaf, choose the downloaded Soloist executable, enter your key, and select **Save Key**, then **Start Soloist**.

The first time, select **Tuneleaf** in Spotify Connect on a Spotify app on the same network. After pairing, you can start listening through Spotify Connect or paste a Spotify URI into Tuneleaf.

## A note on your key

Tuneleaf saves your API key in macOS Keychain. Soloist needs the key to start, and other processes on your Mac may be able to see it while Soloist is running. **Forget** removes the saved key from Tuneleaf but doesn't revoke it at Spotify.

Soloist's local control connection has no authentication, so use Tuneleaf only on a trusted Mac.

## Disclaimer

Tuneleaf is an independent project and is not affiliated with or endorsed by Spotify.
