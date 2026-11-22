import Foundation
import XCTest
@testable import Tuneleaf

@MainActor
final class SoloistManagerTests: XCTestCase {
    func testMissingExecutableReportsError() {
        let manager = SoloistManager()
        manager.start(executable: "/nonexistent/tuneleaf-soloist", key: "test", player: SoloistClient())
        XCTAssertEqual(manager.phase, .stopped)
        XCTAssertEqual(manager.errorMessage, "Choose an executable Spotify Soloist file.")
    }

    func testStartingAndStoppingSelectedProcess() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let executable = root.appendingPathComponent("fake-soloist")
        let script = """
        #!/bin/sh
        while [ "$#" -gt 0 ]; do
          if [ "$1" = "--data-dir" ]; then dir="$2"; shift 2; else shift; fi
        done
        printf '54321' > "$dir/ws.port"
        exec /bin/sleep 30
        """
        try script.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        let manager = SoloistManager(dataDirectory: root.appendingPathComponent("data"),
                                     cacheDirectory: root.appendingPathComponent("cache"))
        let player = SoloistClient()
        defer { manager.stop(); player.disconnect() }

        manager.start(executable: executable.path, key: "test", player: player)
        for _ in 0..<50 where manager.phase == .starting {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertEqual(manager.phase, .running)
        manager.stop()
        player.disconnect()
        XCTAssertEqual(manager.phase, .stopped)
    }

    func testExpiredBuildReportsActionableError() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let executable = root.appendingPathComponent("expired-soloist")
        try "#!/bin/sh\nexit 10\n".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        let manager = SoloistManager(dataDirectory: root.appendingPathComponent("data"),
                                     cacheDirectory: root.appendingPathComponent("cache"))
        defer { manager.stop() }

        manager.start(executable: executable.path, key: "test", player: SoloistClient())
        for _ in 0..<50 where manager.phase != .stopped {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertEqual(manager.phase, .stopped)
        XCTAssertEqual(manager.errorMessage, "Spotify Soloist has expired. Download a newer build from Spotify.")
    }
}
