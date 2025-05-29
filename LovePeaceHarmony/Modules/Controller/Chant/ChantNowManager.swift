//
//  ChantNowManager.swift
//  LovePeaceHarmony
//
//  Created by Cass Pangell on 6/2/24.
//  Copyright © 2025 LovePeaceHarmony. All rights reserved.
//

import Foundation
import UIKit

class ChantNowManager {
    
    static let shared = ChantNowManager()
    
func enableToggleSwitch(for chantFile: ChantFile, in controller: ChantNowController) {
        switch chantFile {
        case .mandarin_soul_english:
            controller.switchMandarinSoulEnglish.isOn = true
        case .instrumental:
            controller.switchInstrumental.isOn = true
        case .hindi_sl_english:
            controller.switchHindiSLEng.isOn = true
        case .spanish:
            controller.switchSpanish.isOn = true
        case .mandarin_english_german:
            controller.switchMandarinEngGerman.isOn = true
        case .french:
            controller.switchFrench.isOn = true
        case .french_antillean_creole:
            controller.switchAntilleanCreole.isOn = true
        case .kawehi_haw:
            controller.switchKawehiHaw.isOn = true
        case .sha_eng:
            controller.switchShaEng.isOn = true
        case .sha_lula_eng_ka_haw:
            controller.switchShaLulaEngKaHaw.isOn = true
        }
        
        // Update the UserDefaults for the enabled switch
        LPHUtils.setUserDefaultsBool(key: getUserDefaultsKey(for: chantFile), value: true)
    }
    
    func getUserDefaultsKey(for chantFile: ChantFile) -> String {
        switch chantFile {
        case .mandarin_soul_english:
            return UserDefaults.Keys.mandarinSoulEnglish
        case .instrumental:
            return UserDefaults.Keys.isInstrumentalOn
        case .hindi_sl_english:
            return UserDefaults.Keys.isHindi_SL_EnglishOn
        case .spanish:
            return UserDefaults.Keys.isSpanishOn
        case .mandarin_english_german:
            return UserDefaults.Keys.isMandarinEnglishGermanOn
        case .french:
            return UserDefaults.Keys.isFrenchOn
        case .french_antillean_creole:
            return UserDefaults.Keys.isfrenchAntilleanCreoleOn
        case .kawehi_haw:
            return UserDefaults.Keys.isKawehiHawOn
        case .sha_eng:
            return UserDefaults.Keys.isShaEngOn
        case .sha_lula_eng_ka_haw:
            return UserDefaults.Keys.isShaLulaEngKaHawOn
        }
    }
    
    func restoreChantSettings(for controller: ChantNowController) {
           // Retrieve song statuses
           let songStatuses = ChantUtils.shared.getSongStatuses()
           
           // Set shuffle and repeat status
           controller.isShuffleEnabled = LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isShuffleEnabled)
           controller.buttonShuffle.tintColor = controller.isShuffleEnabled ? Color.orange : Color.disabled
           
           controller.isRepeatEnabled = LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isRepeatEnabled)
           controller.buttonRepeat.tintColor = controller.isRepeatEnabled ? Color.orange : Color.disabled
           
           // Update song list status
           controller.songListStatus = songStatuses
           
           // Update switches
           controller.switchMandarinSoulEnglish.isOn = songStatuses[.mandarin_soul_english] ?? false
           controller.switchInstrumental.isOn = songStatuses[.instrumental] ?? false
           controller.switchHindiSLEng.isOn = songStatuses[.hindi_sl_english] ?? false
           controller.switchSpanish.isOn = songStatuses[.spanish] ?? false
           controller.switchMandarinEngGerman.isOn = songStatuses[.mandarin_english_german] ?? false
           controller.switchFrench.isOn = songStatuses[.french] ?? false
           controller.switchAntilleanCreole.isOn = songStatuses[.french_antillean_creole] ?? false
           controller.switchKawehiHaw.isOn = songStatuses[.kawehi_haw] ?? false
           controller.switchShaEng.isOn = songStatuses[.sha_eng] ?? false
           controller.switchShaLulaEngKaHaw.isOn = songStatuses[.sha_lula_eng_ka_haw] ?? false
           
           // Update the seek time and slider
           if controller.totalChantDuration != nil {
               let currentTime = TimeInterval(LPHUtils.getUserDefaultsInt(key: UserDefaults.Keys.currentSeek))
               AVAudioManager.sharedInstance.setCurrentTime(timeInterval: currentTime)
               
               let minutes = String(format: "%02d", Int(currentTime / 60))
               let seconds = String(format: "%02d", Int(currentTime.truncatingRemainder(dividingBy: 60)))
               controller.labelSeekTime.text = String("\(minutes):\(seconds)")
               let temp: Float = (Float(currentTime) / controller.totalChantDuration!) / 60
               controller.sliderMusicSeek.setValue(Float(temp), animated: true)
           }
           
           // Set the current song based on song list status
           if let currentSong = controller.songListStatus.first(where: { $0.value })?.key {
               LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: currentSong.rawValue)
           } else {
               LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: -1)
           }
           
           // Initialize song list original
           controller.songListOriginal = ChantUtils.shared.getSongList()
       }
}
