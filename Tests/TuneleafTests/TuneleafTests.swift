import Foundation
import XCTest
@testable import Tuneleaf

final class TuneleafTests: XCTestCase {
    func testPlaybackEventsUpdateAndClearTrack() throws {
        var state = PlayerState()
        let snapshot = """
        {"type":"playback_state","status":"playing","is_active":true,"item":{"decorations":{"identity":{"name":"Song"},"creators":[{"entity":{"decorations":{"identity":{"name":"Artist"}}}}]}}}
        """
        state.apply(try JSONDecoder().decode(SoloistEvent.self, from: Data(snapshot.utf8)))
        XCTAssertEqual(state.title, "Song")
        XCTAssertEqual(state.artist, "Artist")
        XCTAssertEqual(state.status, "playing")
        XCTAssertTrue(state.active)

        let logout = #"{"type":"auth_state","logged_in":false,"is_active":false}"#
        state.apply(try JSONDecoder().decode(SoloistEvent.self, from: Data(logout.utf8)))
        XCTAssertEqual(state.title, "")
        XCTAssertEqual(state.status, "idle")
        XCTAssertFalse(state.loggedIn)
    }

    func testIncrementalPlaybackChangePreservesTrack() throws {
        var state = PlayerState()
        state.title = "Song"
        let event = #"{"type":"playback_changed","status":"paused"}"#
        state.apply(try JSONDecoder().decode(SoloistEvent.self, from: Data(event.utf8)))
        XCTAssertEqual(state.title, "Song")
        XCTAssertEqual(state.status, "paused")
    }

    func testCommandEncodingMatchesSoloistProtocol() throws {
        let data = try JSONEncoder().encode(SoloistCommand(command: "play", uri: "spotify:track:123"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        XCTAssertEqual(json, ["type": "command", "command": "play", "uri": "spotify:track:123"])
    }
}
