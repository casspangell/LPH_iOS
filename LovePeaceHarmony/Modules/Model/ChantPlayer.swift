import AVFoundation
import Combine

// MARK: - ChantPlayerState
enum ChantPlayerState {
    case idle
    case loading
    case playing
    case paused
    case error(Error)
}

// MARK: - ChantPlayerDelegate
protocol ChantPlayerDelegate: AnyObject {
    func chantPlayer(_ player: ChantPlayer, didChangeState state: ChantPlayerState)
    func chantPlayer(_ player: ChantPlayer, didUpdateProgress progress: TimeInterval)
    func chantPlayer(_ player: ChantPlayer, didFinishPlaying chant: ChantFile)
}

// MARK: - ChantPlayer Protocol
protocol ChantPlayerProtocol: AnyObject {
    var delegate: ChantPlayerDelegate? { get set }
    var currentState: ChantPlayerState { get }
    var currentChant: ChantFile? { get }
    var volume: Float { get set }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    
    func prepare(chant: ChantFile) async throws
    func play() async throws
    func pause()
    func stop()
    func seek(to time: TimeInterval)
    func setVolume(_ volume: Float)
}

// MARK: - Modern ChantPlayer Implementation
final class ChantPlayer: NSObject, ChantPlayerProtocol {
    // MARK: - Properties
    weak var delegate: ChantPlayerDelegate?
    private(set) var currentState: ChantPlayerState = .idle {
        didSet {
            delegate?.chantPlayer(self, didChangeState: currentState)
        }
    }
    
    private(set) var currentChant: ChantFile?
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    var volume: Float {
        get { player?.volume ?? 1.0 }
        set { player?.volume = newValue }
    }
    
    var currentTime: TimeInterval {
        player?.currentTime().seconds ?? 0
    }
    
    var duration: TimeInterval {
        player?.currentItem?.duration.seconds ?? 0
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            currentState = .error(error)
        }
    }
    
    // MARK: - Playback Control
    func prepare(chant: ChantFile) async throws {
        currentState = .loading
        currentChant = chant
        
        guard let url = Bundle.main.url(forResource: chant.stringValue, withExtension: "mp3") else {
            throw ChantError.resourceNotFound
        }
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            setupTimeObserver()
            setupNotifications()
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        currentState = .idle
    }
    
    func play() async throws {
        guard let player = player else {
            throw ChantError.playerNotReady
        }
        
        player.play()
        currentState = .playing
    }
    
    func pause() {
        player?.pause()
        currentState = .paused
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        currentState = .idle
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 1000))
    }
    
    func setVolume(_ volume: Float) {
        self.volume = volume
    }
    
    // MARK: - Observation Setup
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.delegate?.chantPlayer(self, didUpdateProgress: time.seconds)
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                guard let self = self,
                      let currentChant = self.currentChant else { return }
                self.delegate?.chantPlayer(self, didFinishPlaying: currentChant)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] notification in
                self?.handleAudioInterruption(notification)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] notification in
                self?.handleRouteChange(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Event Handling
    private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                try? await play()
            }
        @unknown default:
            break
        }
    }
    
    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            pause()
        default:
            break
        }
    }
    
    // MARK: - Cleanup
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        cancellables.removeAll()
    }
}

// MARK: - Errors
extension ChantError {
    static let resourceNotFound = ChantError(rawValue: -1)!
    static let playerNotReady = ChantError(rawValue: -2)!
} 