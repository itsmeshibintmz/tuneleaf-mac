import AVFoundation
import Foundation
import XCTest
@testable import Tuneleaf

@MainActor
final class LocalMusicPlayerTests: XCTestCase {
    func testOpenPlayPauseAndStop() throws {
        let url = try makeAudioFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let player = LocalMusicPlayer()

        player.open(url)
        XCTAssertEqual(player.fileName, url.lastPathComponent)
        XCTAssertNil(player.errorMessage)
        XCTAssertFalse(player.isPlaying)

        player.play()
        XCTAssertTrue(player.isPlaying, player.errorMessage ?? "")
        player.pause()
        XCTAssertFalse(player.isPlaying)
        player.play()
        XCTAssertTrue(player.isPlaying, player.errorMessage ?? "")
        player.stop()
        XCTAssertFalse(player.isPlaying)
    }

    func testInvalidFileReportsErrorAndKeepsPreviousSelection() throws {
        let url = try makeAudioFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let player = LocalMusicPlayer()
        player.open(url)

        player.open(url.appendingPathExtension("missing"))
        XCTAssertEqual(player.fileName, url.lastPathComponent)
        XCTAssertNotNil(player.errorMessage)
        XCTAssertFalse(player.isPlaying)
    }

    func testFinishingFileReturnsToStoppedState() async throws {
        let url = try makeAudioFile(frameCount: 8_820)
        defer { try? FileManager.default.removeItem(at: url) }
        let player = LocalMusicPlayer()
        player.open(url)
        player.play()
        XCTAssertTrue(player.isPlaying, player.errorMessage ?? "")

        for _ in 0..<50 where player.isPlaying {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertFalse(player.isPlaying)
        XCTAssertNil(player.errorMessage)
    }

    private func makeAudioFile(frameCount: AVAudioFrameCount = 44_100 * 5) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        let format = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1))
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount))
        buffer.frameLength = buffer.frameCapacity
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }
}
