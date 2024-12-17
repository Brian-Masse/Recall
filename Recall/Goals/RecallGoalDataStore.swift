//
//  RecallGoalDataModel.swift
//  Recall
//
//  Created by Brian Masse on 8/17/23.
//

import Foundation
import SwiftUI
import UIUniversals
import RealmSwift

//MARK: - RecallGoalHistoryNode
class RecallGoalHistoryNode: Object {
    
//    identification
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String = ""
    
    @Persisted var date: Date = .now
    @Persisted var contributingEvents: RealmSwift.List<ObjectId> = List()
    @Persisted var contributingHours: Double = 0

//    MARK: Init
    convenience init(date: Date) {
        self.init()
        
        self.ownerID = RecallModel.ownerID
        
        self.date = date
        self.contributingHours = 0
    }
    
    func updateContributingHours(to hours: Double) {
        RealmManager.updateObject(self) { thawed in
            thawed.contributingHours = hours
        }
    }
    
    func addEvent(_ event: RecallCalendarEvent) {
        RealmManager.updateObject(self) { thawed in
            thawed.contributingEvents.append(event._id)
        }
    }
    
    func removeEvent(_ event: RecallCalendarEvent) {
        if let index = contributingEvents.firstIndex(of: event._id) {
            RealmManager.updateObject(self) { thawed in
                thawed.contributingEvents.remove(at: index)
            }
        }
    }
}


//MARK: - RecallGoalDataModel
class RecallGoalDataStore: Object {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String = ""
    
    @Persisted private var dataValidated: Bool = false
    @Persisted private var goalId: ObjectId? = nil
    private var goal: RecallGoal? = nil

//    MARK: Init
    convenience init(goal: RecallGoal, newGoal: Bool) {
        self.init()
        self.ownerID = RecallModel.ownerID
        self.goalId = goal._id
        
        Task { self.goal = await getGoal() }
    }
    
//    MARK: - HandleEventUpdate
    @MainActor
    static func handleEventUpdate( _ event: RecallCalendarEvent, updateType: RecallModel.UpdateType ) async {
        switch updateType {
        case .insert:
            await callEventUpdater(event, updater: updateGoalHistoryWithInsertion)
            
        case .delete:
            await callEventUpdater(event, updater: updateGoalHistoryWithDeletion)
            
        case .changeDate:
            await callEventUpdater(event, updater: updateGoalHistoryWithEventDate)
            
        case .changeTime:
            await callEventUpdater(event, updater: updateGoalHistoryWithEventTime)
            
        case .changeGoals:
            await updateGoalHistoryWithGoalRatings(event)
            
        case .update:
            break
        }
    }
    
//    MARK: callEventUpdate
    @MainActor
    static func callEventUpdater( _ event: RecallCalendarEvent,
                                 updater: (RecallCalendarEvent, RecallGoalDataStore) async -> Void ) async {
        let goals: [ RecallGoal ] = RealmManager.retrieveObjectsInList()
        if event.isInvalidated { return }
        
        for goal in goals {
            if event.goalRatings.contains(where: { $0.key == goal.key }) {
                if let dataStore = goal.dataStore {
                    await updater( event, dataStore )
                }
            }
        }
    }
    
    @MainActor
    func checkCorrectness() -> Bool {
        if let node = goalHistory.last {
            var sum: Double = 0
            for id in node.contributingEvents {
                if let event = RecallCalendarEvent.getRecallCalendarEvent(from: id) {
                    sum += event.getLengthInHours()
                }
            }
            
            if node.contributingHours != sum { return false }
        }
        return true
    }
    
//    MARK: - Convenience Functions
    @MainActor
    private func getGoal() -> RecallGoal {
        if goal != nil { return goal! }
        
        return RecallGoal.getGoal(from: goalId!)!
    }
    
    @MainActor
    private func updateDataValidation(to validation: Bool) {
        RealmManager.updateObject(self) { thawed in
            thawed.dataValidated = validation
        }
    }
    
//    MARK: setAllData
    func setAllData() async {
        if dataValidated { return }
        
        await setGoalHistory()
        
        await updateDataValidation(to: true)
    }

//    MARK: - goalHistory
    @Persisted var goalHistory: RealmSwift.List<RecallGoalHistoryNode> = List()
    
    @MainActor
    func updateGoalHistory(with history: [RecallGoalHistoryNode]) {
        let list = RealmSwift.List<RecallGoalHistoryNode>()
        list.append(objectsIn: history)
        
        RealmManager.updateObject(self) { thawed in
            thawed.goalHistory = list
        }
    }
    
//    MARK: setGoalHistory
    @MainActor
    func setGoalHistory() async {
        let events: [RecallCalendarEvent] = RealmManager.retrieveObjectsInList()
        
        let filteredEvents = events
            .filter { $0.getGoalMultiplier(from: getGoal()) > 0 }
            .sorted { $0.startTime < $1.startTime }
        
        var history: [RecallGoalHistoryNode] = []
        var currentDate = Date.distantPast
        var currentHistoryNode = RecallGoalHistoryNode()
        
        for event in filteredEvents {
            if !currentDate.matches(event.startTime, to: .day) {
                currentHistoryNode = RecallGoalHistoryNode(date: event.startTime)
                currentDate = event.startTime
                history.append( currentHistoryNode  )
            }
            
            currentHistoryNode.contributingEvents.append(event._id)
            currentHistoryNode.contributingHours += event.getLengthInHours()
        }
        
        updateGoalHistory(with: history)
    }
    
//    MARK: updateGoalHistorywithInsertion
//    when an event is created, update the history either by creating a new history node, or updating one that already exists
    @MainActor
    static func updateGoalHistoryWithInsertion(
        _ event: RecallCalendarEvent,
        store: RecallGoalDataStore
    ) async {
        var history = Array( store.goalHistory )
        
        if let i = history.firstIndex(where: { node in
            node.date.matches(event.startTime, to: .day)
        }) {
            let node = history[i]
            node.updateContributingHours(to:  node.contributingHours + event.getLengthInHours() )
            node.addEvent(event)
        } else {
            let node = RecallGoalHistoryNode(date: event.startTime)
            node.contributingEvents.append(event._id)
            node.contributingHours += event.getLengthInHours()
            
            history.append(node)
            store.updateGoalHistory(with: history)
        }
    }
    
//    MARK: updateGoalHistoryWithDeletion
//    when an event id deleted, this function updates the history
//    if this event was the only event contributing to a goal on a certain day, this will NOT delete the history node
//    also: it uses the `oldTimes`, because this function is also invoked by the changing date handler
    @MainActor
    static func updateGoalHistoryWithDeletion(
        _ event: RecallCalendarEvent,
        store: RecallGoalDataStore
    ) async {
        let history = Array( store.goalHistory )
        
        if let i = history.firstIndex(where: { node in
            node.date.matches(event.oldStartTime, to: .day)
        }) {
            let node = history[i]
            let oldLength = event.oldEndTime.timeIntervalSince(event.oldStartTime) / Constants.HourTime
            node.updateContributingHours(to: node.contributingHours - oldLength)
            node.removeEvent(event)
        }
    }
    
//    MARK: updateGoalHistoryWithEventData
//    when an events date changes (not time) this function will run to update the history
    @MainActor
    static func updateGoalHistoryWithEventDate(
        _ event: RecallCalendarEvent,
        store: RecallGoalDataStore
    ) async {
//        removes the event from the first day
        await updateGoalHistoryWithDeletion(event, store: store)
        
//        adds it to the second
        await updateGoalHistoryWithInsertion(event, store: store)
    }
    
//    MARK: updateGoalHistoryWithEventTime
//    When an event's time changes (not date) this function will run to update the history
    @MainActor
    static func updateGoalHistoryWithEventTime(
        _ event: RecallCalendarEvent,
        store: RecallGoalDataStore
    ) async {
        let history = Array( store.goalHistory )
        
        if let i = history.firstIndex(where: { node in
            node.date.matches(event.startTime, to: .day)
        }) {
            let oldLength =  event.oldEndTime.timeIntervalSince(event.oldStartTime) / Constants.HourTime
            let newContributingHours: Double = history[i].contributingHours - oldLength + event.getLengthInHours()
            history[i].updateContributingHours(to: newContributingHours)
        }
    }
    
//    MARK: updateGoalHistoryWithGoalRatings
    @MainActor
    static func updateGoalHistoryWithGoalRatings(_ event: RecallCalendarEvent) async {
//        go through all the old ratings and delete any information in them
        for rating in event.oldGoalRatings {
            if let goal = RecallGoal.getGoalFromKey(rating.key) {
                if let store = goal.dataStore {
                    await updateGoalHistoryWithDeletion(event, store: store)
                }
            }
        }

        await handleEventUpdate(event, updateType: .insert)
    }
}
