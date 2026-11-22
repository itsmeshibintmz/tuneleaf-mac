import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct LocalMusicView: View {
    @StateObject private var player = LocalMusicPlayer()

    var body: some View {
        VStack(spacing: 18) {
            Label("Local Music", systemImage: "music.note")
                .font(.title2.bold())
            Text("Choose an audio file from your Mac.")
                .foregroundStyle(.secondary)
            Text(player.fileName ?? "No file selected")
                .lineLimit(1)
                .textSelection(.enabled)
            Button("Choose Audio File...") { chooseAudioFile() }
            HStack(spacing: 16) {
                Button(player.isPlaying ? "Pause" : "Play") {
                    if player.isPlaying {
                        player.pause()
                    } else {
                        player.play()
                    }
                }
                Button("Stop") { player.stop() }
            }
            .disabled(player.fileName == nil)

            if let message = player.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
            Text("Local files and the Spotify prototype play independently.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }

    private func chooseAudioFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.audio]
        if panel.runModal() == .OK, let url = panel.url {
            player.open(url)
        }
    }
}
