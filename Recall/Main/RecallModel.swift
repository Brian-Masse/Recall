//
//  RecallModel.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import UIUniversals

//Main user ownerID
//64b8478c84023dfb762af304
let inDev = true

struct RecallModel {

//        "64ba0fbbd6e75f291b404772"
//        "64b8478c84023dfb762af304"
//  OUTLOOK:    64e4235dadda1f970fc082ed
//  GMAIL:      64e3f9d5ac7aee58fbbceb37
    
//    MARK: Vars
    static var shared: RecallModel = RecallModel()
    static var ownerID: String { RecallModel.realmManager.user?.id ?? "" }
    
    static let dataModel: RecallDataModel = RecallDataModel()
    static let updateManager: UpdateManager = UpdateManager()
    
    @MainActor
    static let realmManager: RealmManager = RealmManager()
    static var index: RecallIndex { RecallModel.realmManager.index  }

    
//    MARK: Methods
    @MainActor
    static func getDaysSinceFirstEvent() -> Double {
        (Date.now.timeIntervalSince(getEarliestEventDate() )) / Constants.DayTime
    }
    
    @MainActor
    static func getEarliestEventDate() -> Date {
        RecallModel.index.earliestEventDate
    }
    
    static func wait(for seconds: Double) async {
        try! await Task.sleep(nanoseconds: UInt64( seconds * pow( 10, 9 )) )
    }

//    MARK: GoalDataModel
//    when data is invalidated, when the user goes to the goals page view
//    it will automatically refresh and re-render all data
//    otherwise, it will just present the pre-rendered data
//    this becomes invalidated anytime there is a change to tags, goals, or events
//    it is not expensive to invalidate this variable (nothing will immediatley change)
//    but it will implicitl queue work for later, so only set it whe its necessary
    private(set) var goalDataValidated: Bool = false
    
    mutating func setGoalDataValidation(to validated: Bool) {
        self.goalDataValidated = validated
    }
    
//    This gets called anytime an event is created, modified, or deleted
//    Any standard update behavior should be included in this function
    func updateEvent(_ event: RecallCalendarEvent) {
        RecallModel.shared.setGoalDataValidation(to: false)
        
        Task { await RecallModel.index.updateEvent(event) }
    }
    
    func updateGoal(_ goal: RecallGoal) {
        RecallModel.shared.setGoalDataValidation(to: false)
    }
    
    func updateTag(_ tag: RecallCategory) {
        RecallModel.shared.setGoalDataValidation(to: false)
    }
    
}
