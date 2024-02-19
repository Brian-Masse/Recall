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

//    MARK: Data Validation
//    when data is invalidated, when the user goes to the goals page view
//    it will automatically refresh and re-render all data
//    otherwise, it will just present the pre-rendered data
//    this becomes invalidated anytime there is a change to tags, goals, or events
//    it is not expensive to invalidate this variable (nothing will immediatley change)
//    but it will implicitl queue work for later, so only set it whe its necessary
    private(set) var goalDataValidated: Bool = false
    
    private(set) var dataOverviewValidated: Bool = false
    private(set) var dataEventsValidated: Bool = false
    private(set) var dataGoalsValidated: Bool = false
    
    mutating func setGoalDataValidation(to validated: Bool) {
        self.goalDataValidated = validated
    }
    
    mutating func setDataOverviewValidation(to validated: Bool) {
        self.dataOverviewValidated = validated
    }
    
    mutating func setDataEventsValidated(to validated: Bool) {
        self.dataEventsValidated = validated
    }
    
    mutating func setDataGoalsValidated(to validated: Bool) {
        self.dataGoalsValidated = validated
    }
    
//    This gets called anytime an event is created, modified, or deleted
//    Any standard update behavior should be included in this function
    func updateEvent(_ event: RecallCalendarEvent) {
        RecallModel.shared.setGoalDataValidation(to: false)
        RecallModel.shared.setDataOverviewValidation(to: false)
        RecallModel.shared.setDataEventsValidated(to: false)
        
        Task { await RecallModel.index.updateEvent(event) }
    }
    
    func updateGoal(_ goal: RecallGoal) {
        RecallModel.shared.setGoalDataValidation(to: false)
        RecallModel.shared.setDataOverviewValidation(to: false)
        RecallModel.shared.setDataGoalsValidated(to: false)
    }
    
    func updateTag(_ tag: RecallCategory) {
        RecallModel.shared.setGoalDataValidation(to: false)
        RecallModel.shared.setDataOverviewValidation(to: false)
        RecallModel.shared.setDataOverviewValidation(to: false)
        RecallModel.shared.setDataGoalsValidated(to: false)
    }
    
}
