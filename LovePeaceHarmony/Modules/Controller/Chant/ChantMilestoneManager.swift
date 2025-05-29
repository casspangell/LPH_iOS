//
//  ChantMilestoneManager.swift
//  LovePeaceHarmony
//
//  Created by Cass Pangell on 6/1/24.
//  Copyright © 2025 LovePeaceHarmony. All rights reserved.
//

import Foundation

class ChantMilestoneManager {
    
    static let shared = ChantMilestoneManager()
    
    func processChantingMilestone(currentTimeString: String, startTimeString: String) {
        // Convert the current time and start time to total seconds
        let currentTimeComponents = currentTimeString.components(separatedBy: ":")
        let currentTimeMinutes = Int(currentTimeComponents[0]) ?? 0
        let currentTimeSeconds = Int(currentTimeComponents[1]) ?? 0
        
        var startTimeMinutes = 0
        var startTimeSeconds = 0
        
        let startTimeComponents = startTimeString.components(separatedBy: ":")
        
        if startTimeComponents.count > 1 {
            startTimeMinutes = Int(startTimeComponents[0]) ?? 0
            startTimeSeconds = Int(startTimeComponents[1]) ?? 0
        }
        
        let currentTimeTotalSeconds = (currentTimeMinutes * 60) + currentTimeSeconds
        let startTimeTotalSeconds = (startTimeMinutes * 60) + startTimeSeconds

        let totalSeconds = currentTimeTotalSeconds - startTimeTotalSeconds
        
        fireMilestoneSavingApi(seconds: totalSeconds)
    }
    
    func fireMilestoneSavingApi(seconds: Int) {
        let currentDate = LPHUtils.getCurrentDate()
        let chantDate = String(currentDate)
        let userId = LPHUtils.getCurrentUserID()
        print("USER \(userId)")
        
        APIUtilities.updateMilestone(date: chantDate, seconds: seconds, userID: userId) { (lphResponse) in
            //Fetch to save in UserDefaults
            APIUtilities.fetchTotalSecsChanted(userID: userId) { (result) in }
        }
       
        APIUtilities.updateChantingStreak(date: chantDate, userID: userId) { (lphResponse) in
            //Fetch to save in UserDefaults
            APIUtilities.fetchCurrentChantingStreak(userID: userId) { (result) in }
        }
    }
}
