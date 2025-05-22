//
//  ChantUtils.swift
//  LovePeaceHarmony
//
//  Created by Cass Pangell on 6/1/24.
//  Copyright © 2024 LovePeaceHarmony. All rights reserved.
//

import UIKit

enum ChantFile: Int, Codable {
    case mandarin_soul_english
    case instrumental
    case hindi_sl_english
    case spanish
    case mandarin_english_german
    case french
    case french_antillean_creole
    case kawehi_haw
    case sha_eng
    case sha_lula_eng_ka_haw

    var stringValue: String {
        switch self {
        case .mandarin_soul_english:
            return "mandarin_soul_english"
        case .instrumental:
            return "instrumental"
        case .hindi_sl_english:
            return "hindi_sl_english"
        case .spanish:
            return "spanish"
        case .mandarin_english_german:
            return "mandarin_english_german"
        case .french:
            return "french"
        case .french_antillean_creole:
            return "french_antillean_creole"
        case .kawehi_haw:
            return "kawehi_haw"
        case .sha_eng:
            return "sha_eng"
        case .sha_lula_eng_ka_haw:
            return "sha_lula_eng_ka_haw"
        }
    }
}

struct ChantFileName {
    static let mandarinSoulEnglish = "MandarinSoulEnglish"
    static let instrumental = "Instrumental"
    static let hindi_sl_english = "HindiSLEnglish"
    static let spanish = "Spanish"
    static let mandarin_english_german = "MandarinEnglishGerman"
    static let french = "French"
    static let french_antillean_creole = "FrenchAntilleanCreole"
    static let kawehi_haw = "KawehiHaw"
    static let sha_eng = "ShaEng"
    static let sha_lula_eng_ka_haw = "ShaLulaEngKaHaw"
}

class ChantUtils {
    
    static let shared = ChantUtils()
    
    func getSongList() -> [ChantFile] {
        return [
            .mandarin_soul_english,
            .instrumental,
            .hindi_sl_english,
            .spanish,
            .mandarin_english_german,
            .french,
            .french_antillean_creole,
            .kawehi_haw,
            .sha_lula_eng_ka_haw,
            .sha_eng
        ]
    }
    
func getSongName(for chantFile: ChantFile) -> String {
        switch chantFile {
        case .mandarin_soul_english:
            return ChantFileName.mandarinSoulEnglish
        case .instrumental:
            return ChantFileName.instrumental
        case .hindi_sl_english:
            return ChantFileName.hindi_sl_english
        case .spanish:
            return ChantFileName.spanish
        case .mandarin_english_german:
            return ChantFileName.mandarin_english_german
        case .french:
            return ChantFileName.french
        case .french_antillean_creole:
            return ChantFileName.french_antillean_creole
        case .kawehi_haw:
            return ChantFileName.kawehi_haw
        case .sha_eng:
            return ChantFileName.sha_eng
        case .sha_lula_eng_ka_haw:
            return ChantFileName.sha_lula_eng_ka_haw
        }
    }
    
    func setLocalizedStrings(
        mandarinSoulEnglishLabel: UILabel,
        instrumentalLabel: UILabel,
        hindiSoulLanguageEnglishLabel: UILabel,
        spanishLabel: UILabel,
        mandarinEnglishGermanLabel: UILabel,
        frenchLabel: UILabel,
        frenchCreoleLabel: UILabel,
        LPHInManyLanguagesBarLable: UILabel,
        expressionsOfLPHBarLabel: UILabel,
        alohaLabel: UILabel,
        lulaliHawaiian: UILabel,
        lphEnglish: UILabel
    ) {
        mandarinSoulEnglishLabel.text = NSLocalizedString("Mandarin, Soul Language, English", comment: "")
        instrumentalLabel.text = NSLocalizedString("Instrumental", comment: "")
        hindiSoulLanguageEnglishLabel.text = NSLocalizedString("Hindi, Soul Language, English", comment: "")
        spanishLabel.text = NSLocalizedString("Spanish, Soul Language", comment: "")
        mandarinEnglishGermanLabel.text = NSLocalizedString("German, English, Mandarin", comment: "")
        frenchLabel.text = NSLocalizedString("Soul Language, French", comment: "")
        frenchCreoleLabel.text = NSLocalizedString("Soul Language, French, Creole", comment: "")
        LPHInManyLanguagesBarLable.text = NSLocalizedString("Love Peace Harmony in Many Languages", comment: "")
        expressionsOfLPHBarLabel.text = NSLocalizedString("Expressions of Love Peace Harmony", comment: "")
        alohaLabel.text = NSLocalizedString("Aloha, Maluhia, Lokahi (LPH in Hawaiian)", comment: "")
        lulaliHawaiian.text = NSLocalizedString("Lu La Li Version, English and Hawaiian", comment: "")
        lphEnglish.text = NSLocalizedString("Love Peace Harmony in English", comment: "")
    }
    
    func getSongStatuses() -> [ChantFile: Bool] {
        return [
            .mandarin_soul_english: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.mandarinSoulEnglish),
            .instrumental: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isInstrumentalOn),
            .hindi_sl_english: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isHindi_SL_EnglishOn),
            .spanish: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isSpanishOn),
            .mandarin_english_german: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isMandarinEnglishGermanOn),
            .french: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isFrenchOn),
            .french_antillean_creole: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isfrenchAntilleanCreoleOn),
            .kawehi_haw: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isKawehiHawOn),
            .sha_eng: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isShaEngOn),
            .sha_lula_eng_ka_haw: LPHUtils.getUserDefaultsBool(key: UserDefaults.Keys.isShaLulaEngKaHawOn)
        ]
    }
    
    func getNextEnabledSong(currentSong: ChantFile?, songListStatus: [ChantFile: Bool]) -> ChantFile? {
        if let currentSong = currentSong {
            for song in getSongList() {
                if songListStatus[song] == true, song != currentSong {
                    return song
                }
            }
        }
        return nil
    }
    
    // Retrieves an array of enabled chant songs in the predefined order.
    // Returns: An array of ChantFiles representing the names of the enabled chant songs in the specific order defined by the `getSongList` method.
    func getSongListArray() -> [ChantFile] {
        let songStatuses = getSongStatuses()
        let orderedSongs = getSongList().filter { songStatuses[$0] == true }
        let enabledSongs = orderedSongs.map { $0 }
        print(enabledSongs)
        return enabledSongs
    }
    
}


