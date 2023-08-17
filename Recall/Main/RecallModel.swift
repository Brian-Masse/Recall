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

@MainActor
struct RecallModel {
    
    static var shared: RecallModel = RecallModel()
    static let realmManager: RealmManager = RealmManager()
    
    static var ownerID: String { RecallModel.realmManager.user?.id ?? "" }
    static var index: RecallIndex { RecallModel.realmManager.index  }
    
    var activeColor: Color = Colors.main
    
    @MainActor
    static func getDaysSinceFirstEvent() -> Double {
        (Date.now.timeIntervalSince(index.earliestEventDate)) / Constants.DayTime
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
