//
//  AVAudioManager.swift
//  LovePeaceHarmony
//
//  Created by Cass Pangell on 6/1/24.
//  Copyright © 2024 LovePeaceHarmony. All rights reserved.
//

import AVFoundation

class AVAudioManager {
    
static let sharedInstance = AVAudioManager()
private var player: AVAudioPlayer?
var isAudioPlaying:Bool? = false

    func prepare() {
        print("[AVAudioManager] prepare called")
        player?.prepareToPlay()
        isAudioPlaying = false
    }

    func loadSong(chantFileName: ChantFile) {
        print("[AVAudioManager] loadSong called with", chantFileName)
        AVAudioManager.sharedInstance.startNewSong(chantFileName: chantFileName.stringValue)
        print("Loaded ", chantFileName)
    }
        
    func startNewSong(chantFileName: String) {
        print("[AVAudioManager] startNewSong called with", chantFileName)
        guard let url = Bundle.main.url(forResource: chantFileName, withExtension: "mp3") else {
            print("[AVAudioManager] ERROR: Could not find mp3 for", chantFileName)
            return
        }
        do {
            // Use string constants for compatibility
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            print("[AVAudioManager] AVAudioPlayer created for", chantFileName)
            self.play()
        } catch let error {
            print("[AVAudioManager] ERROR:", error.localizedDescription)
        }
    }
    
    func playPause(chantArray: [ChantFile: Bool]) {
        print("[AVAudioManager] playPause called. isPlaying:", AVAudioManager.sharedInstance.isPlaying())
        // Check if the audio player is currently playing, if playing, pause the audio
        if AVAudioManager.sharedInstance.isPlaying() {
            print("[AVAudioManager] Pausing audio")
            AVAudioManager.sharedInstance.pause()
        } else {
            // If not playing, check if a song is loaded
            if !AVAudioManager.sharedInstance.isSongLoaded() {
                print("[AVAudioManager] No song loaded, searching for first enabled chant file...")
                // If no song is loaded, find the first enabled chant file from the array
                if let firstEnabledChantFile = chantArray.first(where: { $0.value })?.key {
                    print("[AVAudioManager] Loading first enabled chant file:", firstEnabledChantFile)
                    loadSong(chantFileName: firstEnabledChantFile)
                } else {
                    print("[AVAudioManager] ERROR: No enabled chant files found in array")
                }
                return
            }
            // If a song is already loaded, play the audio
            print("[AVAudioManager] Playing loaded audio")
            AVAudioManager.sharedInstance.play()
        }
    }
    
    func play() {
        print("[AVAudioManager] play called")
        guard let player = player else {
            print("[AVAudioManager] ERROR: player is nil in play()")
            isAudioPlaying = false
            return
        }
        player.play()
        isAudioPlaying = true
        print("[AVAudioManager] player.play() called, isPlaying:", player.isPlaying)
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
