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
        
        self.goal = getGoal()
    }
    
//    MARK: - HandleEventUpdate
    static func handleEventUpdate( _ event: RecallCalendarEvent, updateType: [RecallModel.UpdateType] ) {
//        switch updateType {
//        case .insert:
//            
//            
//        case .delete:
//            
//        case .update:
//            
//        }
    }
    
//    MARK: callEventUpdate
    @MainActor
    static func callEventUpdate( _ event: RecallCalendarEvent,
                                 updater: (RecallCalendarEvent, RecallGoalDataStore) -> Void ) {
        let goals: [ RecallGoal ] = RealmManager.retrieveObjects()
        
        for goal in goals {
            if let dataStore = goal.dataStore {
                updater( event, dataStore )
            }
        }
    }
    
    
//    MARK: - Convenience Functions
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
    
    func setAllData() async {
        if dataValidated { return }
        
        await setGoalHistory()
        
        await updateDataValidation(to: true)
    }

//    MARK: - goalHistory
    @Persisted var goalHistory: RealmSwift.List<RecallGoalHistoryNode> = List()
    
    @MainActor
    private func updateGoalHistory(with history: [RecallGoalHistoryNode]) {
        let list = RealmSwift.List<RecallGoalHistoryNode>()
        list.append(objectsIn: history)
        
        RealmManager.updateObject(self) { thawed in
            thawed.goalHistory = list
        }
    }
    
//    MARK: setGoalHistory
    @MainActor
    func setGoalHistory() async {
        let events: [RecallCalendarEvent] = RealmManager.retrieveObjects()
        
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
}
