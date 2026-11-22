import AVFoundation
import Foundation

@MainActor
final class LocalMusicPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var fileName: String?
    @Published private(set) var isPlaying = false
    @Published var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?

    func open(_ url: URL) {
        do {
            let nextPlayer = try AVAudioPlayer(contentsOf: url)
            nextPlayer.delegate = self
            audioPlayer?.stop()
            audioPlayer = nextPlayer
            fileName = url.lastPathComponent
            isPlaying = false
            errorMessage = nil
        } catch {
            errorMessage = "Could not open this audio file: \(error.localizedDescription)"
        }
    }

    func play() {
        guard let audioPlayer else { return }
        guard audioPlayer.play() else {
            isPlaying = false
            errorMessage = "Could not play this audio file."
            return
        }
        isPlaying = true
        errorMessage = nil
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard self.audioPlayer === player else { return }
            self.isPlaying = false
            if !flag {
                self.errorMessage = "Playback stopped before the file finished."
            }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            guard self.audioPlayer === player else { return }
            self.isPlaying = false
            self.errorMessage = "Could not decode this audio file: \(error?.localizedDescription ?? "Unknown error.")"
        }
    }
}
