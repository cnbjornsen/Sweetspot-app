import Foundation
import AVFoundation
import SweetSpotKit

/// Plays the fanfare sound from inside the app (when foregrounded) so the
/// user gets the same audible cue as they'd get from the lock-screen
/// notification. Mixes with other audio so it doesn't kill background music.
final class FanfarePlayer: @unchecked Sendable {
    private var player: AVAudioPlayer?

    func playIfEnabled(profile: UserProfile?) {
        guard profile?.fanfareEnabled ?? true else { return }
        play()
    }

    func play() {
        guard let url = Bundle.main.url(forResource: "fanfare", withExtension: "caf")
                ?? Bundle.main.url(forResource: "fanfare", withExtension: "wav")
                ?? Bundle.main.url(forResource: "fanfare", withExtension: "mp3")
        else { return }
        do {
            try AVAudioSession.sharedInstance()
                .setCategory(.ambient, mode: .default,
                             options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            // Silent failure — fanfare is non-critical.
        }
    }
}
