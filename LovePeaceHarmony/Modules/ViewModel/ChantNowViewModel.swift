import Foundation
import Combine

// MARK: - ChantNowState
struct ChantNowState {
    var currentChant: ChantFile?
    var enabledChants: Set<ChantFile>
    var isPlaying: Bool
    var isShuffleEnabled: Bool
    var isRepeatEnabled: Bool
    var currentTime: TimeInterval
    var duration: TimeInterval
    var volume: Float
    var error: Error?
    
    static let initial = ChantNowState(
        enabledChants: [],
        isPlaying: false,
        isShuffleEnabled: false,
        isRepeatEnabled: false,
        currentTime: 0,
        duration: 0,
        volume: 0.5
    )
}

// MARK: - ChantNowViewModel
@MainActor
final class ChantNowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state: ChantNowState = .initial
    @Published private(set) var chantPlayer: ChantPlayerProtocol
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    init(
        chantPlayer: ChantPlayerProtocol = ChantPlayer(),
        userDefaults: UserDefaults = .standard
    ) {
        self.chantPlayer = chantPlayer
        self.userDefaults = userDefaults
        
        setupBindings()
        restoreState()
    }
    
    // MARK: - Public Methods
    func toggleChant(_ chant: ChantFile) {
        var enabledChants = state.enabledChants
        
        if enabledChants.contains(chant) {
            enabledChants.remove(chant)
            if state.currentChant == chant {
                stopPlayback()
            }
        } else {
            enabledChants.insert(chant)
            if state.currentChant == nil {
                state.currentChant = chant
                Task {
                    await prepareAndPlay(chant)
                }
            }
        }
        
        state.enabledChants = enabledChants
        saveState()
    }
    
    func togglePlayPause() {
        if state.isPlaying {
            pausePlayback()
        } else {
            Task {
                await resumePlayback()
            }
        }
    }
    
    func toggleShuffle() {
        state.isShuffleEnabled.toggle()
        saveState()
    }
    
    func toggleRepeat() {
        state.isRepeatEnabled.toggle()
        saveState()
    }
    
    func seek(to time: TimeInterval) {
        chantPlayer.seek(to: time)
        state.currentTime = time
    }
    
    func setVolume(_ volume: Float) {
        chantPlayer.setVolume(volume)
        state.volume = volume
        userDefaults.set(volume, forKey: UserDefaults.Keys.playerVolume)
    }
    
    func skipForward() {
        guard let nextChant = getNextChant() else { return }
        playChant(nextChant)
    }
    
    func skipBackward() {
        guard let previousChant = getPreviousChant() else { return }
        playChant(previousChant)
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Handle player state changes
        chantPlayer.delegate = self
    }
    
    private func restoreState() {
        // Restore enabled chants
        let songStatuses = ChantUtils.shared.getSongStatuses()
        state.enabledChants = Set(songStatuses.filter { $0.value }.map { $0.key })
        
        // Restore shuffle and repeat states
        state.isShuffleEnabled = userDefaults.bool(forKey: UserDefaults.Keys.isShuffleEnabled)
        state.isRepeatEnabled = userDefaults.bool(forKey: UserDefaults.Keys.isRepeatEnabled)
        
        // Restore volume
        let volume = userDefaults.float(forKey: UserDefaults.Keys.playerVolume)
        state.volume = volume > 0 ? volume : 0.5
        chantPlayer.setVolume(state.volume)
        
        // Restore last played chant
        if let lastChantRawValue = userDefaults.object(forKey: UserDefaults.Keys.currentChantSong) as? Int,
           let lastChant = ChantFile(rawValue: lastChantRawValue),
           state.enabledChants.contains(lastChant) {
            state.currentChant = lastChant
            Task {
                await prepareAndPlay(lastChant)
            }
        }
    }
    
    private func saveState() {
        // Save enabled chants
        for chant in ChantFile.allCases {
            userDefaults.set(
                state.enabledChants.contains(chant),
                forKey: ChantUtils.shared.getUserDefaultsKey(for: chant)
            )
        }
        
        // Save current chant
        userDefaults.set(
            state.currentChant?.rawValue ?? -1,
            forKey: UserDefaults.Keys.currentChantSong
        )
        
        // Save shuffle and repeat states
        userDefaults.set(
            state.isShuffleEnabled,
            forKey: UserDefaults.Keys.isShuffleEnabled
        )
        userDefaults.set(
            state.isRepeatEnabled,
            forKey: UserDefaults.Keys.isRepeatEnabled
        )
    }
    
    private func playChant(_ chant: ChantFile) {
        state.currentChant = chant
        Task {
            await prepareAndPlay(chant)
        }
        saveState()
    }
    
    private func prepareAndPlay(_ chant: ChantFile) async {
        do {
            try await chantPlayer.prepare(chant: chant)
            try await chantPlayer.play()
        } catch {
            state.error = error
        }
    }
    
    private func stopPlayback() {
        chantPlayer.stop()
        state.currentTime = 0
        state.isPlaying = false
    }
    
    private func pausePlayback() {
        chantPlayer.pause()
        state.isPlaying = false
    }
    
    private func resumePlayback() async {
        if let currentChant = state.currentChant {
            await prepareAndPlay(currentChant)
        }
    }
    
    private func getNextChant() -> ChantFile? {
        guard let currentChant = state.currentChant else { return state.enabledChants.first }
        
        let orderedChants = state.isShuffleEnabled ?
            Array(state.enabledChants).shuffled() :
            ChantUtils.shared.getSongList().filter { state.enabledChants.contains($0) }
        
        guard let currentIndex = orderedChants.firstIndex(of: currentChant) else { return nil }
        let nextIndex = (currentIndex + 1) % orderedChants.count
        return orderedChants[nextIndex]
    }
    
    private func getPreviousChant() -> ChantFile? {
        guard let currentChant = state.currentChant else { return state.enabledChants.first }
        
        let orderedChants = state.isShuffleEnabled ?
            Array(state.enabledChants).shuffled() :
            ChantUtils.shared.getSongList().filter { state.enabledChants.contains($0) }
        
        guard let currentIndex = orderedChants.firstIndex(of: currentChant) else { return nil }
        let previousIndex = (currentIndex - 1 + orderedChants.count) % orderedChants.count
        return orderedChants[previousIndex]
    }
}

// MARK: - ChantPlayerDelegate
extension ChantNowViewModel: ChantPlayerDelegate {
    func chantPlayer(_ player: ChantPlayer, didChangeState state: ChantPlayerState) {
        switch state {
        case .playing:
            self.state.isPlaying = true
        case .paused, .idle:
            self.state.isPlaying = false
        case .loading:
            break
        case .error(let error):
            self.state.error = error
        }
    }
    
    func chantPlayer(_ player: ChantPlayer, didUpdateProgress progress: TimeInterval) {
        state.currentTime = progress
    }
    
    func chantPlayer(_ player: ChantPlayer, didFinishPlaying chant: ChantFile) {
        if state.isRepeatEnabled {
            Task {
                await prepareAndPlay(chant)
            }
        } else if let nextChant = getNextChant() {
            playChant(nextChant)
        } else {
            stopPlayback()
        }
    }
} 