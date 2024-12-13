//
//  RecallModel.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import UIUniversals
import WidgetKit

let inDev = true

struct RecallModel {
//    MARK: Vars
    static var shared: RecallModel = RecallModel()
    static var ownerID: String { RecallModel.realmManager.user?.id ?? "" }
    
    static let dataModel: RecallDataModel = RecallDataModel()
    static let updateManager: UpdateManager = UpdateManager()
    
    static let realmManager: RealmManager = RealmManager()
    static var index: RecallIndex { RecallModel.realmManager.index  }
    static var dataStore: RecallDataStore { RecallModel.realmManager.dataStore  }

    
//    MARK: Methods
//    @MainActor
//    static func getDaysSinceFirstEvent() -> Double {
//        (Date.now.timeIntervalSince(getEarliestEventDate() )) / Constants.DayTime
//    }
//    
    @MainActor
    static func getEarliestEventDate() -> Date {
        RecallModel.index.earliestEventDate
    }
    
    static func wait(for seconds: Double) async {
        do {
            try await Task.sleep(nanoseconds: UInt64( seconds * pow( 10, 9 )) )
        } catch {
            print("failed to complete the wait: \(error.localizedDescription)")
        }
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
    
//    MARK: Updates
    enum UpdateType {
        case insert
        case delete
        case changeDate
        case changeTime
        case changeGoals
        case update
    }
    
//    MARK: - UpdateEvent
//    This gets called anytime an event is created, modified, or deleted
//    Any standard update behavior should be included in this function
    func updateEvent(_ event: RecallCalendarEvent, updateType: UpdateType) {
        RecallModel.shared.setGoalDataValidation(to: false)
        RecallModel.shared.setDataOverviewValidation(to: false)
        RecallModel.shared.setDataEventsValidated(to: false)
        
        if updateType == .changeDate || updateType == .changeTime || updateType == .insert {
            checkUpdateEarliestEvent(event: event)
            updateRecentRecallEventEndTime(to: event.endTime)
        }
        
//        depending on the udpateType, call the relevant data updating methods in the dataStore
        Task {
            await RecallGoalDataStore.handleEventUpdate(event, updateType: updateType)
            
            if updateType == .insert || updateType == .delete {
                await RecallModel.dataStore.insertOrRemoveEventFromMonthLog(event, inserted: updateType == .insert)
            } else {
                await RecallModel.dataStore.changeEventInMonthLog()
            }
        }
    }
    
//    MARK: UpdateEarliestEvent
//    When updating the date compnents for the event, check if it is the earliest event the user has
    private func checkUpdateEarliestEvent(event: RecallCalendarEvent) {
        if Calendar.current.component(.year, from: event.startTime) == 2005 { return }
        if event.startTime < RecallModel.realmManager.index.earliestEventDate {
            RecallModel.realmManager.index.updateEarliestEventDate(with: event.startTime)
        }
    }
    
    private func updateRecentRecallEventEndTime(to time: Date) {
        RecallModel.index.setMostRecentRecallEvent(to: time)
    }
    
//    MARK: - UpdateGoal
    func updateGoal(_ goal: RecallGoal) {
        RecallModel.shared.setGoalDataValidation(to: false)
        RecallModel.shared.setDataOverviewValidation(to: false)
        RecallModel.shared.setDataGoalsValidated(to: false)
    }
    
//    MARK: - UpdateTag
    func updateTag(_ tag: RecallCategory) {
        RecallModel.shared.setGoalDataValidation(to: false)
        RecallModel.shared.setDataOverviewValidation(to: false)
        RecallModel.shared.setDataOverviewValidation(to: false)
        RecallModel.shared.setDataGoalsValidated(to: false)
    }
    
//    MARK: - UpdateEvents
//    This function is called anytime there is a change to the events
    @MainActor
    func updateEvents(_ events: [RecallCalendarEvent]) {
        
        // require that views indirectly dependent on events are re-rendered
        CalendarPageViewModel.shared.resetRenderStatus()
        
        // update the stored data with the new values of events
        RecallModel.dataModel.storeData( events: events)
    }
    
}
