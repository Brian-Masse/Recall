//
//  RecallModel.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI

//Main user ownerID
//64b8478c84023dfb762af304
let inDev = true

struct RecallModel {
    
//  OUTLOOK:    64e4235dadda1f970fc082ed
//  GMAIL:      64e3f9d5ac7aee58fbbceb37
    
    static var shared: RecallModel = RecallModel()
    @MainActor
    static let realmManager: RealmManager = RealmManager()
    
    static var ownerID: String {
        RecallModel.realmManager.user?.id ?? ""
//        "64ba0fbbd6e75f291b404772"
    }
    static var index: RecallIndex { RecallModel.realmManager.index  }
    
//    @MainActor
    private(set) var activeColor: Color = Colors.main
    
    mutating func setActiveColor(from colorScheme: ColorScheme) {
        activeColor = colorScheme == .dark ? Colors.accentGreen : Colors.lightAccentGreen
    }
    
    @MainActor
    static func getDaysSinceFirstEvent() -> Double {
        (Date.now.timeIntervalSince(getEarliestEventDate() )) / Constants.DayTime
    }
    
    @MainActor
    static func getEarliestEventDate() -> Date {
        RecallModel.index.earliestEventDate
    }
    
    @MainActor
    mutating func setTint(from colorScheme: ColorScheme ) {
        activeColor = colorScheme == .dark ? Colors.accentGreen : Colors.lightAccentGreen
    }
    
    static func getTemplates(from events: [RecallCalendarEvent]) -> [RecallCalendarEvent] {
        events.filter { event in event.isTemplate }
    }
    
    static let dataModel: RecallDataModel = RecallDataModel()
}
