import Foundation

@MainActor
final class SoloistManager: ObservableObject {
    enum Phase {
        case stopped, starting, running
    }

    @Published private(set) var phase: Phase = .stopped
    @Published var errorMessage: String?

    private var process: Process?
    private var startupTask: Task<Void, Never>?
    private let dataDirectory: URL?
    private let cacheDirectory: URL?

    init(dataDirectory: URL? = nil, cacheDirectory: URL? = nil) {
        self.dataDirectory = dataDirectory
        self.cacheDirectory = cacheDirectory
    }

    func start(executable: String, key: String, player: SoloistClient) {
        guard phase == .stopped else { return }
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            errorMessage = "Choose an executable Spotify Soloist file."
            return
        }
        do {
            let support = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true
            )
            let caches = try FileManager.default.url(
                for: .cachesDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true
            )
            let root = dataDirectory ?? support.appendingPathComponent("Tuneleaf/Soloist", isDirectory: true)
            let cache = cacheDirectory ?? caches.appendingPathComponent("Tuneleaf/Soloist", isDirectory: true)
            try FileManager.default.createDirectory(
                at: root, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try FileManager.default.createDirectory(
                at: cache, withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            let portFile = root.appendingPathComponent("ws.port")
            let previousModification = modificationDate(of: portFile)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = [
                "--device-name", "Tuneleaf", "--api-key", key,
                "--data-dir", root.path, "--cache-dir", cache.path, "--ws", "127.0.0.1:0",
                "--cache-size", "100"
            ]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { [weak self] finished in
                let code = finished.terminationStatus
                Task { @MainActor [weak self] in
                    self?.didExit(finished, code: code, player: player)
                }
            }
            try process.run()
            self.process = process
            errorMessage = nil
            phase = .starting
            startupTask = Task {
                for _ in 0..<100 {
                    if Task.isCancelled || !process.isRunning { return }
                    if let modification = modificationDate(of: portFile),
                       modification != previousModification,
                       let raw = try? String(contentsOf: portFile, encoding: .utf8) {
                        let port = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let number = Int(port), (1...65535).contains(number) {
                            phase = .running
                            player.connect(port: port)
                            return
                        }
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                guard !Task.isCancelled else { return }
                stop()
                errorMessage = "Soloist did not expose a local control port within 10 seconds."
            }
        } catch {
            errorMessage = "Could not start Spotify Soloist: \(error.localizedDescription)"
        }
    }

    func stop() {
        startupTask?.cancel()
        startupTask = nil
        if let process, process.isRunning {
            process.terminate()
        }
        process = nil
        phase = .stopped
    }

    private func didExit(_ finished: Process, code: Int32, player: SoloistClient) {
        guard process === finished else { return }
        process = nil
        startupTask?.cancel()
        startupTask = nil
        phase = .stopped
        player.disconnect()
        if code == 10 {
            errorMessage = "Spotify Soloist has expired. Download a newer build from Spotify."
        } else {
            errorMessage = "Spotify Soloist stopped (exit code \(code)). Check its setup and try again."
        }
    }

    private func modificationDate(of url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
    }
}
