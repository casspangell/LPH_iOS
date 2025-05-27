import Foundation

extension UserDefaults {
    enum Keys {
        // MARK: - Chant Settings
        static let currentChantSong = "currentChantSong"
        static let currentSeek = "currentSeek"
        static let playerVolume = "playerVolume"
        static let isShuffleEnabled = "isShuffleEnabled"
        static let isRepeatEnabled = "isRepeatEnabled"
        
        // MARK: - Chant Toggles
        static let mandarinSoulEnglish = "mandarinSoulEnglish"
        static let isInstrumentalOn = "isInstrumentalOn"
        static let isHindi_SL_EnglishOn = "isHindi_SL_EnglishOn"
        static let isSpanishOn = "isSpanishOn"
        static let isMandarinEnglishGermanOn = "isMandarinEnglishGermanOn"
        static let isFrenchOn = "isFrenchOn"
        static let isfrenchAntilleanCreoleOn = "isfrenchAntilleanCreoleOn"
        static let isKawehiHawOn = "isKawehiHawOn"
        static let isShaEngOn = "isShaEngOn"
        static let isShaLulaEngKaHawOn = "isShaLulaEngKaHawOn"
        
        // MARK: - App State
        static let isTutorialShown = "isTutorialShown"
        static let isFirstRun = "isFirstRun"
    }
    
    // MARK: - Convenience Methods
    func set(_ value: Any?, forKey key: String, synchronize: Bool = true) {
        set(value, forKey: key)
        if synchronize {
            UserDefaults.standard.synchronize()
        }
    }
    
    func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        return object(forKey: key) as? Bool ?? defaultValue
    }
    
    func integer(forKey key: String, defaultValue: Int = 0) -> Int {
        return object(forKey: key) as? Int ?? defaultValue
    }
    
    func float(forKey key: String, defaultValue: Float = 0.0) -> Float {
        return object(forKey: key) as? Float ?? defaultValue
    }
    
    func string(forKey key: String, defaultValue: String? = nil) -> String? {
        return object(forKey: key) as? String ?? defaultValue
    }
    
    func data(forKey key: String, defaultValue: Data? = nil) -> Data? {
        return object(forKey: key) as? Data ?? defaultValue
    }
    
    func array(forKey key: String, defaultValue: [Any]? = nil) -> [Any]? {
        return object(forKey: key) as? [Any] ?? defaultValue
    }
    
    func dictionary(forKey key: String, defaultValue: [String: Any]? = nil) -> [String: Any]? {
        return object(forKey: key) as? [String: Any] ?? defaultValue
    }
    
    // MARK: - Chant-specific Methods
    func isChantEnabled(_ chant: ChantFile) -> Bool {
        return bool(forKey: ChantUtils.shared.getUserDefaultsKey(for: chant))
    }
    
    func setChantEnabled(_ enabled: Bool, for chant: ChantFile) {
        set(enabled, forKey: ChantUtils.shared.getUserDefaultsKey(for: chant))
    }
    
    func currentChant() -> ChantFile? {
        let rawValue = integer(forKey: Keys.currentChantSong)
        return ChantFile(rawValue: rawValue)
    }
    
    func setCurrentChant(_ chant: ChantFile?) {
        set(chant?.rawValue ?? -1, forKey: Keys.currentChantSong)
    }
    
    func currentSeek() -> TimeInterval {
        return TimeInterval(integer(forKey: Keys.currentSeek))
    }
    
    func setCurrentSeek(_ seek: TimeInterval) {
        set(Int(seek), forKey: Keys.currentSeek)
    }
    
    func playerVolume() -> Float {
        return float(forKey: Keys.playerVolume, defaultValue: 0.5)
    }
    
    func setPlayerVolume(_ volume: Float) {
        set(volume, forKey: Keys.playerVolume)
    }
    
    func isShuffleEnabled() -> Bool {
        return bool(forKey: Keys.isShuffleEnabled)
    }
    
    func setShuffleEnabled(_ enabled: Bool) {
        set(enabled, forKey: Keys.isShuffleEnabled)
    }
    
    func isRepeatEnabled() -> Bool {
        return bool(forKey: Keys.isRepeatEnabled)
    }
    
    func setRepeatEnabled(_ enabled: Bool) {
        set(enabled, forKey: Keys.isRepeatEnabled)
    }
    
    func isTutorialShown() -> Bool {
        return bool(forKey: Keys.isTutorialShown)
    }
    
    func setTutorialShown(_ shown: Bool) {
        set(shown, forKey: Keys.isTutorialShown)
    }
    
    func isFirstRun() -> Bool {
        return integer(forKey: Keys.isFirstRun) == 0
    }
    
    func setFirstRunCompleted() {
        set(1, forKey: Keys.isFirstRun)
    }
} 