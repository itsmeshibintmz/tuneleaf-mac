import AppKit
import SwiftUI

struct PlayerView: View {
    @ObservedObject var player: SoloistClient
    @ObservedObject var soloist: SoloistManager
    @AppStorage("soloistPath") private var soloistPath = ""
    @State private var key = ""
    @State private var port = "9090"
    @State private var uri = ""
    @State private var setupMessage: String?

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Tuneleaf", systemImage: "waveform")
                    .font(.title2.bold())
                Spacer()
                Text(connectionLabel)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 7) {
                Image(systemName: "music.note")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text(player.state.title.isEmpty ? "Nothing playing" : player.state.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(player.state.artist.isEmpty ? "Connect to Spotify Soloist to begin" : player.state.artist)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 115)

            HStack(spacing: 24) {
                Button { player.send("skip_prev") } label: {
                    Image(systemName: "backward.end.fill")
                }
                .help("Previous track")
                Button {
                    player.send(player.state.status == "playing" ? "pause" : "play")
                } label: {
                    Image(systemName: player.state.status == "playing" ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .help(player.state.status == "playing" ? "Pause" : "Play")
                Button { player.send("skip_next") } label: {
                    Image(systemName: "forward.end.fill")
                }
                .help("Next track")
            }
            .buttonStyle(.borderless)
            .disabled(player.connection != .connected || !player.state.loggedIn)

            HStack {
                TextField("Spotify URI (track, album or playlist)", text: $uri)
                    .textFieldStyle(.roundedBorder)
                Button("Play URI") {
                    let value = uri.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !value.isEmpty else {
                        player.errorMessage = "Enter a Spotify URI to play."
                        return
                    }
                    player.send("play", uri: value)
                }
                .disabled(player.connection != .connected || !player.state.loggedIn)
            }

            Divider()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Spotify Soloist").font(.headline)
                    Spacer()
                    Link("Download", destination: URL(string: "https://developer.spotify.com/documentation/soloist/reference/downloads-and-updates")!)
                    Link("Get API key", destination: URL(string: "https://developer.spotify.com/dashboard/soloist")!)
                }
                HStack {
                    Text(soloistPath.isEmpty ? "No executable selected" : URL(fileURLWithPath: soloistPath).lastPathComponent)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose...") { chooseSoloist() }
                        .disabled(soloist.phase != .stopped)
                }
                HStack {
                    SecureField("Soloist API key", text: $key)
                        .textFieldStyle(.roundedBorder)
                    Button("Save Key") { saveKey() }
                        .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Forget") { forgetKey() }
                }
                HStack {
                    if soloist.phase == .stopped {
                        Button("Start Soloist") { startSoloist() }
                    } else {
                        Button(soloist.phase == .starting ? "Stop Starting" : "Stop Soloist") {
                            soloist.stop()
                            player.disconnect()
                        }
                    }
                    Text(soloistStatus)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Text("First time: select Tuneleaf in Spotify Connect on the same network.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Or connect to a running Soloist:")
                TextField("9090", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 75)
                if player.connection == .disconnected {
                    Button("Connect") { player.connect(port: port) }
                        .disabled(soloist.phase != .stopped)
                } else {
                    Button("Disconnect") { player.disconnect() }
                        .disabled(soloist.phase != .stopped)
                }
                Spacer()
            }
            if let message = soloist.errorMessage ?? player.errorMessage ?? setupMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(24)
    }

    private func chooseSoloist() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose the Spotify Soloist executable downloaded from Spotify."
        if panel.runModal() == .OK, let url = panel.url {
            soloistPath = url.path
        }
    }

    private func saveKey() {
        clearMessages()
        do {
            try Keychain.save(key.trimmingCharacters(in: .whitespacesAndNewlines))
            key = ""
            setupMessage = nil
        } catch {
            setupMessage = "Could not save the key: \(error.localizedDescription)"
        }
    }

    private func forgetKey() {
        clearMessages()
        do {
            try Keychain.remove()
            key = ""
            setupMessage = nil
        } catch {
            setupMessage = "Could not remove the key: \(error.localizedDescription)"
        }
    }

    private func startSoloist() {
        clearMessages()
        do {
            let savedKey = try Keychain.load()
            setupMessage = nil
            soloist.start(executable: soloistPath, key: savedKey, player: player)
        } catch {
            setupMessage = error.localizedDescription
        }
    }

    private func clearMessages() {
        soloist.errorMessage = nil
        player.errorMessage = nil
        setupMessage = nil
    }

    private var soloistStatus: String {
        switch soloist.phase {
        case .stopped: return "Stopped"
        case .starting: return "Starting..."
        case .running: return "Running"
        }
    }

    private var connectionLabel: String {
        switch player.connection {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected:
            return player.state.loggedIn ? "Connected" : "Pair in Spotify"
        }
    }
}
