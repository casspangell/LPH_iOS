//
//  AVAudioManager.swift
//  LovePeaceHarmony
//
//  Created by Cass Pangell on 6/1/24.
//  Copyright © 2025 LovePeaceHarmony. All rights reserved.
//

import AVFoundation

class AVAudioManager: NSObject, AVAudioPlayerDelegate {
    
    static let sharedInstance = AVAudioManager()
    private var player: AVAudioPlayer?
    var isAudioPlaying:Bool? = false
    
    // Debug logging
    private var debugLogs: [String] = []
    var onLogUpdate: (([String]) -> Void)?
    
    // AVAudioPlayerDelegate methods
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        addDebugLog("Audio player finished playing. Success: \(flag)")
        isAudioPlaying = false
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            addDebugLog("❌ Audio player decode error: \(error.localizedDescription)")
        } else {
            addDebugLog("❌ Audio player decode error occurred")
        }
    }
    
    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        debugLogs.append(logMessage)
        if debugLogs.count > 100 { // Keep last 100 logs
            debugLogs.removeFirst()
        }
        onLogUpdate?(debugLogs)
        print(logMessage) // Also print to console
    }
    
    func getDebugLogs() -> [String] {
        return debugLogs
    }
    
    func clearDebugLogs() {
        debugLogs.removeAll()
        onLogUpdate?(debugLogs)
    }

    func prepare() {
        addDebugLog("Prepare called")
        player?.prepareToPlay()
        isAudioPlaying = false
    }

    func loadSong(chantFileName: ChantFile) {
        addDebugLog("Load song called with \(chantFileName)")
        AVAudioManager.sharedInstance.startNewSong(chantFileName: chantFileName.stringValue)
        addDebugLog("Loaded \(chantFileName)")
    }
        
    func startNewSong(chantFileName: String) {
        addDebugLog("\n=== Starting New Song ===")
        addDebugLog("Attempting to load song: \(chantFileName)")
        
        guard let url = Bundle.main.url(forResource: chantFileName, withExtension: "mp3") else {
            addDebugLog("❌ ERROR: Could not find MP3 file in bundle")
            addDebugLog("Looking for: \(chantFileName).mp3")
            addDebugLog("Bundle paths:")
            Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil).forEach { addDebugLog("- \($0)") }
            return
        }
        addDebugLog("✅ Found MP3 file at: \(url.path)")
        
        do {
            addDebugLog("\n=== Configuring Audio Session ===")
            let audioSession = AVAudioSession.sharedInstance()
            addDebugLog("Current audio session category: \(audioSession.category)")
            addDebugLog("Current audio session mode: \(audioSession.mode)")
            addDebugLog("Current audio session options: \(audioSession.categoryOptions)")
            
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
            addDebugLog("✅ Audio session configured successfully")
            
            addDebugLog("\n=== Creating Audio Player ===")
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            player?.prepareToPlay()
            player?.delegate = self
            
            addDebugLog("Audio player details:")
            addDebugLog("- Duration: \(player?.duration ?? 0) seconds")
            addDebugLog("- Format: \(player?.format.description ?? "unknown")")
            addDebugLog("- Number of channels: \(player?.numberOfChannels ?? 0)")
            addDebugLog("- Volume: \(player?.volume ?? 0)")
            
            addDebugLog("\n=== Starting Playback ===")
            self.play()
        } catch let error {
            addDebugLog("\n❌ ERROR in audio setup:")
            addDebugLog("Error description: \(error.localizedDescription)")
            addDebugLog("Error details: \(error)")
            addDebugLog("Error domain: \(error._domain)")
            addDebugLog("Error code: \(error._code)")
        }
    }
    
    func playPause(chantArray: [ChantFile: Bool]) {
        print("\n=== DEBUG: Play/Pause Called ===")
        print("Current playing state: \(AVAudioManager.sharedInstance.isPlaying())")
        
        if AVAudioManager.sharedInstance.isPlaying() {
            print("Pausing audio...")
            AVAudioManager.sharedInstance.pause()
        } else {
            if !AVAudioManager.sharedInstance.isSongLoaded() {
                print("No song loaded, checking for enabled chants...")
                print("Enabled chants:")
                chantArray.forEach { print("- \($0.key): \($0.value)") }
                
                if let firstEnabledChantFile = chantArray.first(where: { $0.value })?.key {
                    print("Loading first enabled chant: \(firstEnabledChantFile)")
                    loadSong(chantFileName: firstEnabledChantFile)
                } else {
                    print("❌ No enabled chants found")
                }
                return
            }
            print("Playing loaded audio...")
            AVAudioManager.sharedInstance.play()
        }
    }
    
    func play() {
        addDebugLog("\n=== Play Called ===")
        guard let player = player else {
            addDebugLog("❌ ERROR: Audio player is nil")
            isAudioPlaying = false
            return
        }
        
        addDebugLog("Current player state:")
        addDebugLog("- Duration: \(player.duration) seconds")
        addDebugLog("- Current time: \(player.currentTime) seconds")
        addDebugLog("- Number of channels: \(player.numberOfChannels)")
        addDebugLog("- Format: \(player.format.description)")
        addDebugLog("- Volume: \(player.volume)")
        addDebugLog("- Is playing: \(player.isPlaying)")
        
        let success = player.play()
        addDebugLog("\nPlayback attempt result:")
        addDebugLog("- Success: \(success)")
        addDebugLog("- Is playing after play(): \(player.isPlaying)")
        addDebugLog("- Current time after play(): \(player.currentTime)")
        
        isAudioPlaying = success
    }
    
    func pause() {
        print("[AVAudioManager] pause called")
        player?.pause()
        isAudioPlaying = false
    }
    
    func stop() {
        print("[AVAudioManager] stop called")
        player?.stop()
        isAudioPlaying = false
    }
    
    func isPlaying() -> Bool {
        let playing = player?.isPlaying ?? false
        print("[AVAudioManager] isPlaying:", playing)
        return playing
    }
    
    func isSongLoaded() -> Bool {
        let loaded = player?.url != nil
        print("[AVAudioManager] isSongLoaded:", loaded)
        return loaded
    }
    
    func getCurrentTime() -> Double {
        return player?.currentTime ?? 0.0
    }
    
    
    func setVolume(volume: Float) {
        player?.volume = volume
    }
    
    func setCurrentTime(timeInterval: Double) {
        player?.currentTime = timeInterval
    }
    
    func setPlayerNil() {
        player = nil
    }
    
}
