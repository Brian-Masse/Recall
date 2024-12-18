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
    
//    these two variables are here so that when filtering by tag, the front end does not need to find the calendar events
//    with the coorespondings IDs, filter them, and then sum their total hours.
//    This adds considerable complexity to maintaining the accuracy of the nodes, and I'm not sure if this is the long term solution
    @Persisted var contributingTags: RealmSwift.List<ObjectId> = List()
    @Persisted var contributingHoursByEvent: RealmSwift.List<Double> = List()
    
    @Persisted private var contributingHours: Double = 0
    
    func getContributingHours(filteringBy tagId: ObjectId? = nil) -> Double {
        var sum: Double = 0
        for i in 0..<contributingHoursByEvent.count {
            if let tagId { if contributingTags[i] != tagId { continue } }
            sum += contributingHoursByEvent[i]
        }
        return sum
    }

//    MARK: Init
    convenience init(date: Date) {
        self.init()
        
        self.ownerID = RecallModel.ownerID
        
        self.date = date
        self.contributingHours = 0
    }
    
    func updateContributingHours(_ event: RecallCalendarEvent) {
        if let index = contributingEvents.firstIndex(of: event._id) {
            RealmManager.updateObject(self) { thawed in
                thawed.contributingHoursByEvent[index] = event.getLengthInHours()
            }
        }
    }
    
    func addEvent(_ event: RecallCalendarEvent) {
        RealmManager.updateObject(self) { thawed in
            thawed.contributingEvents.append(event._id)
            thawed.contributingTags.append(event.category?._id ?? .init())
            thawed.contributingHoursByEvent.append(event.getLengthInHours())
        }
    }
    
    func removeEvent(_ event: RecallCalendarEvent) {
        if let index = contributingEvents.firstIndex(of: event._id) {
            RealmManager.updateObject(self) { thawed in
                thawed.contributingEvents.remove(at: index)
                thawed.contributingTags.remove(at: index)
                thawed.contributingHoursByEvent.remove(at: index)
            }
        }
    }
    
    func checkCorrectness() -> Bool {
        (self.contributingEvents.count == self.contributingTags.count) && (self.contributingHoursByEvent.count == self.contributingEvents.count)
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
    
//    MARK: getCurrentGoalProgress
    func getCurrentGoalProgress(goalFrequency: Int) async -> Double {
        let count = goalHistory.count
        let historySubset = Array(goalHistory[ (count - 7)..<count ])
        
//        get the start of the time period
        let startOfWeek = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: .now).date! - Constants.DayTime
        let startDate = goalFrequency == 7 ? startOfWeek : .now
        
        let contributingNodes = historySubset.filter{ $0.date >= startDate }
        return contributingNodes.reduce(0) { partialResult, node in
            partialResult + node.getContributingHours()
        }
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
        await setTotalContributions()
        await setTotalContributingHours()
        
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
            
            let hours = event.getLengthInHours()
            
            currentHistoryNode.contributingEvents.append(event._id)
            currentHistoryNode.contributingTags.append(event.category?._id ?? .init())
            currentHistoryNode.contributingHoursByEvent.append(hours)
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
            node.addEvent(event)
        } else {
            let node = RecallGoalHistoryNode(date: event.startTime)
            node.contributingEvents.append(event._id)
//            node.contributingHours += event.getLengthInHours()
            
            history.append(node)
            store.updateGoalHistory(with: history)
        }
        
        store.incrementToatlContributions(by: 1)
        store.incrementTotalContributingHours(by: event.getLengthInHours())
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
            node.removeEvent(event)
        }
        
        store.incrementToatlContributions(by: -1)
        store.incrementTotalContributingHours(by: -event.getLengthInHours())
        
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
            history[i].updateContributingHours(event)
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
    
//    MARK: totalContributions
    @Persisted var totalContributions: Int = 0
    
    @MainActor
    private func setTotalContributions(to totalContributions: Int) {
        RealmManager.updateObject(self) { thawed in
            thawed.totalContributions = totalContributions
        }
    }
    
    @MainActor
    private func incrementToatlContributions(by amount: Int) {
        RealmManager.updateObject(self) { thawed in
            thawed.totalContributions += amount
        }
    }
    
    func setTotalContributions() async {
        var totalContributions: Int = 0
        for node in goalHistory {
            totalContributions += node.contributingEvents.count
        }
        
        await setTotalContributions(to: totalContributions)
    }
    
    func getContributionFrequency() -> Double {
        Double(totalContributions) / Double(RecallModel.index.daysSinceFirstEvent())
    }
    
//    MARK: totalContributingHours
    @Persisted var totalContributingHours: Double = 0
    
    
    @MainActor
    private func setTotalContributingHours(to totalContributingHours: Double) {
        RealmManager.updateObject(self) { thawed in
            thawed.totalContributingHours = totalContributingHours
        }
    }
    
    @MainActor
    private func incrementTotalContributingHours(by amount: Double) {
        RealmManager.updateObject(self) { thawed in
            thawed.totalContributingHours += amount
        }
    }
    
    func setTotalContributingHours() async {
        var totalContributingHours: Double = 0
        for node in goalHistory {
            totalContributingHours += node.getContributingHours()
        }
        
        await setTotalContributingHours(to: totalContributingHours)
    }
    
    func getAverageHourlyContribution() -> Double {
        Double(totalContributingHours) / Double(self.totalContributions)
    }
}
