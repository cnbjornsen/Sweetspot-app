import Foundation

/// Random-but-non-repeating supplier of quotes and memes.
/// Maintains an LRU of recent IDs to suppress repeats inside a single session.
public final class QuoteLibrary: @unchecked Sendable {
    public static let shared = QuoteLibrary()

    private let lock = NSLock()
    private var quotes: [Quote] = []
    private var memes: [Meme] = []
    private var recent: [UUID] = []
    private let recentCapacity = 20

    private init() {
        load()
    }

    // MARK: Loading

    private func load() {
        if let url = Bundle.module.url(forResource: "quotes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Quote].self, from: data) {
            quotes = decoded
        } else {
            quotes = QuoteLibrary.fallbackQuotes
        }

        if let url = Bundle.module.url(forResource: "memes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Meme].self, from: data) {
            memes = decoded
        } else {
            memes = []
        }
    }

    // MARK: Public API

    public func random(for mood: QuoteMood) -> Quote? {
        lock.lock(); defer { lock.unlock() }
        let pool = quotes.filter { $0.mood == mood && !recent.contains($0.id) }
        let candidates = pool.isEmpty ? quotes.filter { $0.mood == mood } : pool
        guard let pick = weightedRandom(candidates) else { return nil }
        remember(pick.id)
        return pick
    }

    public func randomMeme(for mood: QuoteMood) -> Meme? {
        lock.lock(); defer { lock.unlock() }
        let pool = memes.filter { $0.mood == mood && !recent.contains($0.id) }
        let candidates = pool.isEmpty ? memes.filter { $0.mood == mood } : pool
        guard let pick = candidates.randomElement() else { return nil }
        remember(pick.id)
        return pick
    }

    /// Deterministic-per-day selection — useful for widget timeline stability.
    public func dailyQuote(for mood: QuoteMood, on date: Date = .now) -> Quote? {
        let pool = quotes.filter { $0.mood == mood }
        guard !pool.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return pool[day % pool.count]
    }

    public func resetSessionMemory() {
        lock.lock(); defer { lock.unlock() }
        recent.removeAll()
    }

    // MARK: Helpers

    private func remember(_ id: UUID) {
        recent.append(id)
        if recent.count > recentCapacity {
            recent.removeFirst(recent.count - recentCapacity)
        }
    }

    private func weightedRandom(_ pool: [Quote]) -> Quote? {
        guard !pool.isEmpty else { return nil }
        let totalWeight = pool.reduce(0) { $0 + max(1, $1.weight) }
        var roll = Int.random(in: 0..<totalWeight)
        for q in pool {
            roll -= max(1, q.weight)
            if roll < 0 { return q }
        }
        return pool.last
    }

    /// Tiny built-in fallback so the app still has voice if the JSON is missing.
    private static let fallbackQuotes: [Quote] = [
        Quote(text: "You're doing great. Pace yourself.", mood: .encouraging),
        Quote(text: "Sip, don't gulp.", mood: .encouraging),
        Quote(text: "Be honest — your future self will thank you.", mood: .cautionary),
        Quote(text: "Cheers! Time for the next one. 🎉", mood: .fanfare),
        Quote(text: "Welcome. Let's find your sweet spot.", mood: .onboarding),
        Quote(text: "Numbers don't lie. Memories do.", mood: .stat),
    ]
}
