import AppKit
import SwiftUI

@main
struct TuneleafApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var player = SoloistClient()
    @StateObject private var soloist = SoloistManager()

    var body: some Scene {
        WindowGroup {
            TabView {
                LocalMusicView()
                    .tabItem { Label("Local Music", systemImage: "music.note") }
                PlayerView(player: player, soloist: soloist)
                    .tabItem { Label("Spotify Prototype", systemImage: "waveform") }
            }
                .frame(minWidth: 480, minHeight: 490)
                .onAppear { delegate.soloist = soloist }
        }
        .windowResizability(.contentMinSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var soloist: SoloistManager?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        soloist?.stop()
    }
}
