//
//  ChantNowController.swift
//  LovePeaceHarmony
//
//  Created by Cass Pangell on 6/1/24.
//  Copyright © 2024 LovePeaceHarmony. All rights reserved.
//

import UIKit
import EventKit
import XLPagerTabStrip
import AVFoundation
import Firebase
import MaterialShowcase

class ChantNowController: BaseViewController, IndicatorInfoProvider, AVAudioPlayerDelegate {
    
    // MARK: - Variables
    var sliderTimer: Timer?
    var totalChantDuration: Float?
    var startTime: String?
    var songListStatus = [ChantFile: Bool]()
    var songListOriginal = [ChantFile]()
    var songListShuffled = [ChantFile]()
    var currentSong: ChantFile?
    var currentSongString: String?

    var isShuffleEnabled = false
    var isRepeatEnabled = false
    var chantMilestoneCounter:Float = 0
    var chantTitle = ["Mandarin, Soul Language, English", "Instrumental", "Hindi, Soul Language, English", "Spanish, Soul Language", "German, English, Mandarin", "Soul Language, French", "Soul Language, French, Creole", "Aloha, Maluhia, Lokahi (LPH in Hawaiian)", "Lu La Li Version, English and Hawaiian", "Love Peace Harmony in English"]
  
    // MARK: - IBProperties
    @IBOutlet weak var buttonPlayPause: UIButton!
    @IBOutlet weak var labelSeekTime: UILabel!
    @IBOutlet weak var labelTotalDuration: UILabel!
    @IBOutlet weak var sliderMusicSeek: UISlider!
    @IBOutlet weak var sliderVolume: UISlider!
    
    @IBOutlet weak var switchMandarinSoulEnglish: UISwitch!
    @IBOutlet weak var switchInstrumental: UISwitch!
    @IBOutlet weak var switchHindiSLEng: UISwitch!
    @IBOutlet weak var switchSpanish: UISwitch!
    @IBOutlet weak var switchMandarinEngGerman: UISwitch!
    @IBOutlet weak var switchFrench: UISwitch!
    @IBOutlet weak var switchAntilleanCreole: UISwitch!
    @IBOutlet weak var switchKawehiHaw: UISwitch!
    @IBOutlet weak var switchShaLulaEngKaHaw: UISwitch!
    @IBOutlet weak var switchShaEng: UISwitch!
    
    @IBOutlet weak var mandarinSoulEnglishLabel: UILabel!
    @IBOutlet weak var instrumentalLabel: UILabel!
    @IBOutlet weak var hindiSoulLanguageEnglishLabel: UILabel!
    @IBOutlet weak var spanishLabel: UILabel!
    @IBOutlet weak var mandarinEnglishGermanLabel: UILabel!
    @IBOutlet weak var frenchLabel: UILabel!
    @IBOutlet weak var frenchCreoleLabel: UILabel!
    
    @IBOutlet weak var LPHInManyLanguagesBarLable: UILabel!
    @IBOutlet weak var expressionsOfLPHBarLabel: UILabel!
    
    @IBOutlet weak var alohaLabel: UILabel!
    @IBOutlet weak var lulaliHawaiian: UILabel!
    @IBOutlet weak var lphEnglish: UILabel!
    
    @IBOutlet weak var buttonShuffle: UIButton!
    @IBOutlet weak var buttonRepeat: UIButton!
    @IBOutlet weak var labelSongName: UILabel!

    // MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()

        ChantUtils.shared.setLocalizedStrings(
                mandarinSoulEnglishLabel: mandarinSoulEnglishLabel,
                instrumentalLabel: instrumentalLabel,
                hindiSoulLanguageEnglishLabel: hindiSoulLanguageEnglishLabel,
                spanishLabel: spanishLabel,
                mandarinEnglishGermanLabel: mandarinEnglishGermanLabel,
                frenchLabel: frenchLabel,
                frenchCreoleLabel: frenchCreoleLabel,
                LPHInManyLanguagesBarLable: LPHInManyLanguagesBarLable,
                expressionsOfLPHBarLabel: expressionsOfLPHBarLabel,
                alohaLabel: alohaLabel,
                lulaliHawaiian: lulaliHawaiian,
                lphEnglish: lphEnglish
            )
        
        sliderMusicSeek.setThumbImage(#imageLiteral(resourceName: "ic_slider_thumb"), for: .normal)
        sliderMusicSeek.setThumbImage(#imageLiteral(resourceName: "ic_slider_thumb"), for: .selected)
        sliderMusicSeek.setThumbImage(#imageLiteral(resourceName: "ic_slider_thumb"), for: .focused)
        sliderMusicSeek.setThumbImage(#imageLiteral(resourceName: "ic_slider_thumb"), for: .highlighted)
        
        sliderMusicSeek.isUserInteractionEnabled = false
        
        initiateMusicPlayer()
        updateToggleSwitches()
        
        if isShuffleEnabled {
            generateShuffleList()
        }
        
//        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    

    override func viewDidAppear(_ animated: Bool) {
        
        //If in another class or view pauses the player
        let image = buttonPlayPause.imageView?.image
        
        let audioBool = AVAudioManager.sharedInstance.isPlaying()
        if (image == #imageLiteral(resourceName: "ic_pause")) && (!audioBool) {
            buttonPlayPause.setImage(#imageLiteral(resourceName: "ic_play"), for: .normal)//play image
        }
    }
    
    func renderShowcaseView() {
        LPHUtils.renderShowcaseView(title: NSLocalizedString("Turn on / off chants", comment: ""), view: switchMandarinSoulEnglish, delegate: nil, secondaryText: NSLocalizedString("Use the switches to customize your chanting playlist.", comment: ""))
//        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isTutorialShown, value: true)
    }
    
    // MARK: - XLPagerTabStrip
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Title")
    }
    
    
    private func generateShuffleList() {
        let enabledSongs = ChantUtils.shared.getSongListArray()
        songListShuffled = enabledSongs.shuffled()

        // Debug print
        print("---shuffled song list---")
        for song in songListShuffled {
            print(song)
        }
    }

    
    private func updateToggleSwitches() {
        // Retrieve song statuses
        let songStatuses = ChantUtils.shared.getSongStatuses()

        // Update switches based on the song statuses
        switchMandarinSoulEnglish.isOn = songStatuses[.mandarin_soul_english] ?? false
        switchInstrumental.isOn = songStatuses[.instrumental] ?? false
        switchHindiSLEng.isOn = songStatuses[.hindi_sl_english] ?? false
        switchSpanish.isOn = songStatuses[.spanish] ?? false
        switchMandarinEngGerman.isOn = songStatuses[.mandarin_english_german] ?? false
        switchFrench.isOn = songStatuses[.french] ?? false
        switchAntilleanCreole.isOn = songStatuses[.french_antillean_creole] ?? false
        switchKawehiHaw.isOn = songStatuses[.kawehi_haw] ?? false
        switchShaEng.isOn = songStatuses[.sha_eng] ?? false
        switchShaLulaEngKaHaw.isOn = songStatuses[.sha_lula_eng_ka_haw] ?? false
    }
    
    private func initiateMusicPlayer() {
        print("initiateMusicPlayer")
        // Prepare music player
        AVAudioManager.sharedInstance.prepare()
        
        // Slider targets
//        sliderMusicSeek.addTarget(self, action: #selector(sliderTouchDown), for: UIControlEvents.touchDown)
//        sliderMusicSeek.addTarget(self, action: #selector(sliderRelease), for: UIControlEvents.touchUpInside)

        // Retrieve song statuses and ordered enabled songs
        let orderedEnabledSongs = ChantUtils.shared.getSongListArray()

        // Find the first song that is enabled
        guard !orderedEnabledSongs.isEmpty else {
            labelTotalDuration.text = "-:-"
            return
        }

        // Set the current song
        currentSong = orderedEnabledSongs.first
        renderSongName(title: chantTitle[(currentSong?.rawValue)!])
        labelSeekTime.text = "00:00"

        // Get the song name
        currentSongString = ChantUtils.shared.getSongName(for: currentSong!)

        // Prepare the song
        guard let url = Bundle.main.url(forResource: currentSongString, withExtension: "mp3") else { return }

        togglePlayPauseButton()

        // Get song duration
        let asset = AVURLAsset(url: url)
        totalChantDuration = Float((CMTimeGetSeconds(asset.duration)) / 60)

        let totalMinute = Int(totalChantDuration!)
        let decimalMinute: Float = (totalChantDuration! - Float(totalMinute)) * 100
        let originalMinute: Int = Int(decimalMinute * 0.6)
        labelTotalDuration.text = "\(totalMinute).\(originalMinute)"

        // Settings volume to previous value
        var volume = LPHUtils.getUserDefaultsFloat(key: UserDefaults.Keys.playerVolume)
        if volume == 0 {
            volume = 30
        }

        AVAudioManager.sharedInstance.setVolume(volume: volume)
        sliderVolume.setValue(volume / 100, animated: false)

        // Setting to previous seek position
        let currentTime = TimeInterval(LPHUtils.getUserDefaultsInt(key: UserDefaults.Keys.currentSeek))
        AVAudioManager.sharedInstance.setCurrentTime(timeInterval: currentTime)

        // Grabs the current timestamp for more accurate chanting time
        print("Set START TIME \(currentTime)")
        startTime = String(currentTime)
        updateSlider()
    }

    
    @objc func updateSlider() {
        
            let currentTime = AVAudioManager.sharedInstance.getCurrentTime()

            chantMilestoneCounter += 1
            let milestoneTempMinutes = chantMilestoneCounter.truncatingRemainder(dividingBy: 600)
            if milestoneTempMinutes == 0 {
                let pendingMilestonesTemp = Int(chantMilestoneCounter / 600)
                LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.chantMinutePendingTemp, value: pendingMilestonesTemp)
            }
            
            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentSeek, value: Int(currentTime))
            let minutes = String(format: "%02d", Int(currentTime / 60))

            let seconds = String(format: "%02d", Int(currentTime.truncatingRemainder(dividingBy: 60)))
            labelSeekTime.text = String("\(minutes):\(seconds)")

            totalChantDuration = totalChantDuration ?? 0
        
            var temp: Float = (Float(currentTime) / totalChantDuration!) / 60
            if temp != 1 && temp > 1 {
                temp = 0
//                audioPlayerDidFinishPlaying()
//                togglePlayPauseButton()
            }
        
            sliderMusicSeek.setValue(Float(temp), animated: true)
    }
    
    @objc func sliderTouchDown(sender: UISlider) {
        print("touch down")
        //process milestone with touch down value
        
        togglePlayPauseButton()
    }
    
    @objc func sliderRelease(sender: UISlider) {
        print("release")
        //update start time to release value
        startTime = labelSeekTime.text //set new start time
        togglePlayPauseButton()
        
    }
    
    private func togglePlayPauseButton() {
        // Check and print the song list before attempting playback
        let songList = ChantUtils.shared.getSongListArray()
        print("[DEBUG] Song list at play:", songList)
        if songList.isEmpty {
            showToast(message: NSLocalizedString("No songs selected for playback.", comment: ""))
            return
        }
        // If no song is selected, select the first song (.mandarin_soul_english) and start playback
        if currentSong == nil {
            currentSong = .mandarin_soul_english
            currentSongString = currentSong?.stringValue
            // Enable the switch for .mandarin_soul_english if not already enabled
            songListStatus[.mandarin_soul_english] = true
            renderSongName(title: chantTitle[ChantFile.mandarin_soul_english.rawValue])
            initiateMusicPlayer()
        }
        let audioPlayer = AVAudioManager()
        let songStatuses = ChantUtils.shared.getSongStatuses()
        audioPlayer.playPause(chantArray: songStatuses)
        
        if AVAudioManager.sharedInstance.isPlaying() {
            buttonPlayPause.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.isFirstRun, value: 1)
            startTime = labelSeekTime.text // Set new start time
            sliderTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ChantNowController.updateSlider), userInfo: nil, repeats: true)
            let isFirstRun = LPHUtils.getUserDefaultsInt(key: UserDefaults.Keys.isFirstRun)
            // If first run, start default song, else continue from the current song
            if isFirstRun == 0 {
                AVAudioManager.sharedInstance.startNewSong(chantFileName: currentSongString!)
            } else {
                AVAudioManager.sharedInstance.play()
            }
        } else {
            buttonPlayPause.setImage(#imageLiteral(resourceName: "ic_play"), for: .normal)
//            ChantMilestoneManager.shared.processChantingMilestone()
            startTime = labelSeekTime.text // Set new start time
            sliderTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ChantNowController.updateSlider), userInfo: nil, repeats: true)
        }
    }
    
    private func pressedSkipForward() {
        // Use shuffled list if shuffle is enabled
        let enabledSongs: [ChantFile]
        if isShuffleEnabled, !songListShuffled.isEmpty {
            enabledSongs = songListShuffled
        } else {
            enabledSongs = ChantUtils.shared.getSongListArray()
        }
        guard let currSong = currentSong else { return }

        // Find the current song index
        guard let currentIndex = enabledSongs.firstIndex(of: currSong) else { return }

        // Calculate the next song index
        let nextIndex = (currentIndex + 1) % enabledSongs.count

        // Get the next song's name
        let nextSongName = enabledSongs[nextIndex]
        
        //Update current song to new one
        currentSong = nextSongName

        // Find the corresponding ChantFile for the next song
        guard let nextSong = ChantUtils.shared.getSongList().first(where: { $0.stringValue == nextSongName.stringValue }) else { return }

        // Update user defaults
        LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: nextSong.rawValue)

        // Start the new song using AVAudioManager
        AVAudioManager.sharedInstance.startNewSong(chantFileName: nextSong.stringValue)

        // Render song name on the UI
        renderSongName(title: chantTitle[nextSong.rawValue])

        // Invalidate the existing slider timer
        sliderTimer?.invalidate()

        // Set new start time
        startTime = labelSeekTime.text

        // Schedule the new slider timer
        sliderTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)

        // Update play/pause button image
        buttonPlayPause.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
    }
    
    private func pressedSkipBackward() {
        // Use shuffled list if shuffle is enabled
        let enabledSongs: [ChantFile]
        if isShuffleEnabled, !songListShuffled.isEmpty {
            enabledSongs = songListShuffled
        } else {
            enabledSongs = ChantUtils.shared.getSongListArray().filter { songListStatus[$0] == true }
        }
        guard let currSong = currentSong else { return }

        // Find the current song index
        guard let currentIndex = enabledSongs.firstIndex(of: currSong) else { return }

        // Calculate the previous song index
        let previousIndex = (currentIndex - 1 + enabledSongs.count) % enabledSongs.count

        // Get the previous song's name
        let previousSongName = enabledSongs[previousIndex]

        // Update current song to new one
        currentSong = ChantUtils.shared.getSongList().first(where: { $0 == previousSongName })

        guard let previousSong = currentSong else { return }

        // Update user defaults
        LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: previousSong.rawValue)

        // Start the new song using AVAudioManager
        AVAudioManager.sharedInstance.startNewSong(chantFileName: previousSong.stringValue)

        // Render song name on the UI
        renderSongName(title: chantTitle[previousSong.rawValue])

        // Invalidate the existing slider timer
        sliderTimer?.invalidate()

        // Set new start time
        startTime = labelSeekTime.text

        // Schedule the new slider timer
        sliderTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)

        // Update play/pause button image
        buttonPlayPause.setImage(#imageLiteral(resourceName: "ic_pause"), for: .normal)
    }


    
    private func renderSongName(title: String) {
//        let songTitle = chantTitle[(currentSong?.rawValue)!]
        print("song title \(title)")
        if currentSong != nil {
            labelSongName.text = "\(NSLocalizedString("Now Playing: ", comment: "")) \(NSLocalizedString(title, comment: ""))"
        } else {
            labelSongName.text = " "
        }
    }
    
    private func forceStopPlaying(chantSong: ChantFile) {
        ChantMilestoneManager.shared.processChantingMilestone(currentTimeString: labelSeekTime.text ?? "", startTimeString: startTime ?? "")

        if currentSong == chantSong {
            if AVAudioManager.sharedInstance.isPlaying() {
                AVAudioManager.sharedInstance.stop()
            }

            labelSeekTime.text = "0:0"
            labelTotalDuration.text = "-:-"
            sliderMusicSeek.setValue(0, animated: true)
            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentSeek, value: 0)

            if let nextSong = ChantUtils.shared.getNextEnabledSong(currentSong: currentSong, songListStatus: songListStatus) {
                currentSong = nextSong
                LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: nextSong.rawValue)
            } else {
                LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: -1)
                showToast(message: NSLocalizedString(AlertMessage.enableSong, comment: ""))
            }

            renderSongName(title: chantTitle[(currentSong?.rawValue)!])
            initiateMusicPlayer()
            togglePlayPauseButton()
        }

        if currentSong == nil {
            currentSong = ChantUtils.shared.getNextEnabledSong(currentSong: nil, songListStatus: songListStatus)
            renderSongName(title: chantTitle[(currentSong?.rawValue)!])
        }

        if let currentSong = currentSong {
            labelSeekTime.text = "0:0"
            sliderMusicSeek.setValue(0, animated: true)
            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentSeek, value: 0)
        } else {
            labelTotalDuration.text = "-:-"
        }

        LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: currentSong?.rawValue ?? -1)
    }

    private func checkAndTurnShuffleRepeatOff() -> Bool {
        var turnAllOff = true
        for song in songListStatus {
            if song.value {
                turnAllOff = false
                break
            }
        }
        if turnAllOff {
            LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isShuffleEnabled, value: false)
            LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isRepeatEnabled, value: false)
            isShuffleEnabled = false
            isRepeatEnabled = false
            buttonRepeat.tintColor = Color.disabled
            buttonShuffle.tintColor = Color.disabled
            AVAudioManager.sharedInstance.setPlayerNil()
            sliderTimer?.invalidate()
            togglePlayPauseButton()
        }
        return turnAllOff
    }
    
    private func resetAudioPlayer() {

        if (AVAudioManager.sharedInstance.isPlaying()) {
            AVAudioManager.sharedInstance.stop()
        }

        labelSeekTime.text = "0:0"
        labelTotalDuration.text = "-:-"
        sliderMusicSeek.setValue(0, animated: true)
        LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentSeek, value: 0)
    }
    
    func audioPlayerDidFinishPlaying() {
        sliderTimer?.invalidate()
        if currentSong != nil {
            pressedSkipForward()
        }
    }
    
    //MARK: - IBActions
    @IBAction func onTapPlay(_ sender: UIButton) {
        animateMusicButton(sender, 0) {}
        togglePlayPauseButton()
    }
    
    @IBAction func onTapPreviousSong(_ sender: UIButton) {
       pressedSkipBackward()
    }
    
    @IBAction func onTapNextSong(_ sender: UIButton) {
       pressedSkipForward()
    }
    
    @IBAction func onTapShuffle(_ sender: UIButton) {
        print("shuffle")
            isShuffleEnabled = !isShuffleEnabled
            if isShuffleEnabled {
                print("shuffle on")
                showToast(message: NSLocalizedString(AlertMessage.shuffleOn, comment: ""))
                let enabledSongs = ChantUtils.shared.getSongListArray()
                songListShuffled = enabledSongs.shuffled()
                sender.tintColor = Color.orange
                isShuffleEnabled = true
            } else {
                print("shuffle off")
                showToast(message: NSLocalizedString(AlertMessage.shuffleOff, comment: ""))
                songListShuffled = []
                sender.tintColor = Color.disabled
                isShuffleEnabled = false
            }
            LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isShuffleEnabled, value: isShuffleEnabled)
    }
    
    @IBAction func onTapReplay(_ sender: UIButton) {
        if !checkAndTurnShuffleRepeatOff() {
            isRepeatEnabled = !isRepeatEnabled
            if isRepeatEnabled {
                showToast(message: NSLocalizedString(AlertMessage.repeatOn, comment: "") )
            } else {
                showToast(message: NSLocalizedString(AlertMessage.repeatOff, comment: ""))
            }
            LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isRepeatEnabled, value: isRepeatEnabled)
            if isRepeatEnabled {
                sender.tintColor = Color.orange
            } else {
                sender.tintColor = Color.disabled
            }
        } else {
            showToast(message: NSLocalizedString(AlertMessage.enableSong, comment: ""))
        }
    }
    
    @IBAction func onSliderVolumeChanged(_ sender: UISlider) {
        let volume: Float = sender.value
        AVAudioManager.sharedInstance.setVolume(volume: volume)
        LPHUtils.setUserDefaultsFloat(key: UserDefaults.Keys.playerVolume, value: volume)
    }
    
    @IBAction func onSliderSeekValueChanged(_ sender: UISlider) {
        let interval = TimeInterval(sender.value * 60 * totalChantDuration!)
        AVAudioManager.sharedInstance.setCurrentTime(timeInterval:interval)

        updateSlider()
    }
    
    @IBAction func onTapSwitchMandarinSoulEnglish(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.mandarinSoulEnglish, value: sender.isOn)
        songListStatus[.mandarin_soul_english] = sender.isOn
    }
    
    @IBAction func onTapSwitchInstrumental(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isInstrumentalOn, value: sender.isOn)
        songListStatus[.instrumental] = sender.isOn
    }
    
    @IBAction func onTapSwitchHindiSLEnglish(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isHindi_SL_EnglishOn, value: sender.isOn)
        songListStatus[.hindi_sl_english] = sender.isOn
    }
    
    @IBAction func onTapSpanish(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isSpanishOn, value: sender.isOn)
        songListStatus[.spanish] = sender.isOn
    }
    
    @IBAction func onTapMandarinEngGerman(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isMandarinEnglishGermanOn, value: sender.isOn)
        songListStatus[.mandarin_english_german] = sender.isOn
    }
    
    @IBAction func onTapFrench(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isFrenchOn, value: sender.isOn)
        songListStatus[.french] = sender.isOn
    }
    
    @IBAction func onTapAntilleanCreole(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isfrenchAntilleanCreoleOn, value: sender.isOn)
        songListStatus[.french_antillean_creole] = sender.isOn
    }

    @IBAction func onTapKawehiHaw(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isKawehiHawOn, value: sender.isOn)
        songListStatus[.kawehi_haw] = sender.isOn
    }
    
    @IBAction func onTapShaLulaEngKaHaw(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isShaLulaEngKaHawOn, value: sender.isOn)
        songListStatus[.sha_lula_eng_ka_haw] = sender.isOn
    }

    @IBAction func onTapShaEng(_ sender: UISwitch) {
        LPHUtils.setUserDefaultsBool(key: UserDefaults.Keys.isShaEngOn, value: sender.isOn)
        songListStatus[.sha_eng] = sender.isOn
    }
    
// MARK: OnTap Gestures

    @IBAction func onTapInstrumentalGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .instrumental)
    }
    
    @IBAction func onTapMandarinSLEngGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .mandarin_soul_english)
    }
    
    @IBAction func onTapHindiSLEngGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .hindi_sl_english)
    }
    
    @IBAction func onTapSpanishGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .spanish)
    }
    
    @IBAction func onTapMandarinEngGerGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .mandarin_english_german)
    }
    
    @IBAction func onTapFrenchGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .french)
    }
    
    @IBAction func onTapFrenchCreoleGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .french_antillean_creole)
    }
    
    @IBAction func onTapHawaiianGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .kawehi_haw)
    }
    
    @IBAction func onTapSLEngHawaiianGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .sha_lula_eng_ka_haw)
    }
    
    @IBAction func onTapEnglishGesture(_ sender: UITapGestureRecognizer) {
        updateSwitch(chantFile: .sha_eng)
    }
    

    private func updateSwitch(chantFile: ChantFile) {
        if let isEnabled = songListStatus[chantFile], isEnabled {
            // Update user defaults
            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentSeek, value: 0)
            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: chantFile.rawValue)

            // Start the new song using AVAudioManager
            AVAudioManager.sharedInstance.startNewSong(chantFileName: chantFile.stringValue)

            // Render song name on the UI
            renderSongName(title: chantTitle[chantFile.rawValue])

        } else {
            // Enable the toggle switch for the chantFile using ChantNowManager
            ChantNowManager.shared.enableToggleSwitch(for: chantFile, in: self)

            // Update the songListStatus dictionary
            songListStatus[chantFile] = true

            // Update user defaults
            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentSeek, value: 0)
            LPHUtils.setUserDefaultsInt(key: UserDefaults.Keys.currentChantSong, value: chantFile.rawValue)

            // Start the new song using AVAudioManager
            AVAudioManager.sharedInstance.startNewSong(chantFileName: chantFile.stringValue)

            // Render song name on the UI
            renderSongName(title: chantTitle[chantFile.rawValue])
        }
    }


    func animateMusicButton(_ view: UIView, _ duration: Double, completionListener: @escaping () -> Void) {
        UIView.animate(withDuration: duration, delay: (TimeInterval(0)), usingSpringWithDamping: 1, initialSpringVelocity: 5, options: .curveEaseInOut,
                       animations: {
                        view.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)},completion: { [weak self] finished in
                            self?.animateOutMusicButton(view, duration, completionListener)
        })
    }
    
    func animateOutMusicButton(_ view: UIView, _ duration: Double, _ completionListener: @escaping () -> Void) {
        UIView.animate(withDuration: 0.5, delay: (TimeInterval(0)), usingSpringWithDamping: 1, initialSpringVelocity: 5, options: .curveEaseInOut,
                       animations: {
                        view.transform = CGAffineTransform(scaleX: 1, y: 1)},completion: { finished in
                            completionListener()
                            
        })
    }
    
}
