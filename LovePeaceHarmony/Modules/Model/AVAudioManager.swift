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
        player?.prepareToPlay()
        isAudioPlaying = false
    }

    func loadSong(chantFileName: ChantFile) {
        AVAudioManager.sharedInstance.startNewSong(chantFileName: chantFileName.stringValue)
        print("Loaded ", chantFileName)
    }
        
    func startNewSong(chantFileName: String) {
        guard let url = Bundle.main.url(forResource: chantFileName, withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with:AVAudioSessionCategoryOptions.defaultToSpeaker)
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            self.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playPause(chantArray: [ChantFile: Bool]) {
        // Check if the audio player is currently playing, if playing, pause the audio
        if AVAudioManager.sharedInstance.isPlaying() {
            AVAudioManager.sharedInstance.pause()
        } else {
            // If not playing, check if a song is loaded
            if !AVAudioManager.sharedInstance.isSongLoaded() {
                // If no song is loaded, find the first enabled chant file from the array
                if let firstEnabledChantFile = chantArray.first(where: { $0.value })?.key {
                    loadSong(chantFileName: firstEnabledChantFile)
                }
                return
            }
            // If a song is already loaded, play the audio
            AVAudioManager.sharedInstance.play()
        }
    }
    
    func play() {
        player?.play()
        isAudioPlaying = true
    }
    
    func pause() {
        player?.pause()
        isAudioPlaying = false
    }
    
    func stop() {
        player?.stop()
        isAudioPlaying = false
    }
    
    func isPlaying() -> Bool {
        print(player?.isPlaying ?? false)
        return player?.isPlaying ?? false
    }
    
    func isSongLoaded() -> Bool {
        return player?.url != nil
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
