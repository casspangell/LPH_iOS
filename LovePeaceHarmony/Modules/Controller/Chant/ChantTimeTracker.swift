import Foundation

class ChantTimeTracker {
    static let shared = ChantTimeTracker()
    
    private var timer: Timer?
    private var secondsAccumulated: Int = 0
    private var isTracking: Bool = false
    private var lastStartDate: Date?
    private let userDefaultsKey = "ChantTimeTracker.secondsAccumulated"
    private let userDefaultsDateKey = "ChantTimeTracker.lastTrackedDate"
    
    private init() {
        loadState()
    }
    
    func start() {
        guard !isTracking else { return }
        isTracking = true
        lastStartDate = Date()
        startTimer()
    }
    
    func pause() {
        guard isTracking else { return }
        accumulateTime()
        stopTimer()
        isTracking = false
    }
    
    func resume() {
        guard !isTracking else { return }
        isTracking = true
        lastStartDate = Date()
        startTimer()
    }
    
    func stopAndFlush() {
        accumulateTime()
        stopTimer()
        isTracking = false
        if secondsAccumulated > 0 {
            // Save to server
            ChantMilestoneManager.shared.fireMilestoneSavingApi(seconds: secondsAccumulated)
        }
        reset()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func timerFired() {
        accumulateTime()
        saveState()
    }
    
    private func accumulateTime() {
        guard let lastStart = lastStartDate else { return }
        let now = Date()
        let interval = Int(now.timeIntervalSince(lastStart))
        secondsAccumulated += interval
        lastStartDate = now
        saveState()
    }
    
    private func saveState() {
        let today = Self.currentDateString()
        UserDefaults.standard.set(secondsAccumulated, forKey: userDefaultsKey)
        UserDefaults.standard.set(today, forKey: userDefaultsDateKey)
    }
    
    private func loadState() {
        let today = Self.currentDateString()
        let savedDate = UserDefaults.standard.string(forKey: userDefaultsDateKey)
        if savedDate == today {
            secondsAccumulated = UserDefaults.standard.integer(forKey: userDefaultsKey)
        } else {
            secondsAccumulated = 0
        }
    }
    
    private func reset() {
        secondsAccumulated = 0
        lastStartDate = nil
        saveState()
    }
    
    static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // For UI
    func getAccumulatedSeconds() -> Int {
        if isTracking, let lastStart = lastStartDate {
            return secondsAccumulated + Int(Date().timeIntervalSince(lastStart))
        } else {
            return secondsAccumulated
        }
    }
} 