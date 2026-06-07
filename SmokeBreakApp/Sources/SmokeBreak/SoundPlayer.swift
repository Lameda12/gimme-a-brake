import AppKit
import AVFoundation

enum SoundTier: String {
    case low, medium, high

    /// Token-spend buckets. Tune thresholds as usage patterns become clearer.
    static func forTokenCount(_ tokens: Int?) -> SoundTier {
        guard let tokens else { return .low }
        switch tokens {
        case ..<50_000: return .low
        case 50_000..<150_000: return .medium
        default: return .high
        }
    }
}

@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var player: AVAudioPlayer?
    private let lastPlayedKey = "SmokeBreak.lastPlayed"

    private init() {}

    func play(tier: SoundTier) {
        let clips = clipURLs(for: tier)
        guard !clips.isEmpty else { return }

        let lastPlayed = loadLastPlayed()
        var pool = clips
        if pool.count > 1, let last = lastPlayed[tier.rawValue] {
            pool.removeAll { $0.lastPathComponent == last }
        }
        guard let chosen = pool.randomElement() else { return }

        var updated = lastPlayed
        updated[tier.rawValue] = chosen.lastPathComponent
        saveLastPlayed(updated)

        do {
            let p = try AVAudioPlayer(contentsOf: chosen)
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            NSSound(contentsOf: chosen, byReference: true)?.play()
        }
    }

    private func clipURLs(for tier: SoundTier) -> [URL] {
        guard let dir = Bundle.main.url(forResource: "Sounds", withExtension: nil)?
            .appendingPathComponent(tier.rawValue) else { return [] }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil
        )) ?? []
        return files.filter { ["mp3", "wav", "m4a", "caf", "aiff"].contains($0.pathExtension.lowercased()) }
    }

    private func loadLastPlayed() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: lastPlayedKey) as? [String: String] ?? [:]
    }

    private func saveLastPlayed(_ dict: [String: String]) {
        UserDefaults.standard.set(dict, forKey: lastPlayedKey)
    }
}
