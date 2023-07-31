//
//  RecallGoal.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import RealmSwift

//    MARK: Goal Node
//    These will be stored in calendar events,
//    the key represents the label of the goal the data is associated with
//    The data will be the goal rating for that event (ie. 5 points of "productivity" or 0 points of "social")
class GoalNode: Object, Identifiable {
   
    @Persisted(primaryKey: true) var _id: ObjectId
   
    @Persisted var ownerID: String = ""
    @Persisted var key: String = ""
    @Persisted var data: String = ""
   
    convenience init( ownerID: String, key: String, data: String ) {
        self.init()
       
        self.ownerID = ownerID
        self.key = key
        self.data = data
    }
}

//    MARK: RecallGoal
class RecallGoal: Object, Identifiable {
    
    enum GoalFrequence: String, Identifiable, CaseIterable {
        case daily
        case weekly
        
        var id: String { self.rawValue }
        
        var numericValue: Int {
            switch self {
            case .weekly: return 7
            case .daily: return 1
            }
        }
        
        static func getType(from frequence: Int) -> String {
            if frequence == RecallGoal.GoalFrequence.weekly.numericValue { return "weekly goal" }
            if frequence == RecallGoal.GoalFrequence.daily.numericValue { return "daily goal" }
            return "?"
        }
        
        static func getRawType(from frequence: Int) -> GoalFrequence {
            if frequence == RecallGoal.GoalFrequence.weekly.numericValue { return .weekly }
            if frequence == RecallGoal.GoalFrequence.daily.numericValue { return .daily }
            return .daily
        }
    }
    
    enum GoalType: String, Identifiable, CaseIterable {
        case hourly
        case byTag
        
        var id: String { self.rawValue }
        
        static func getRawType(from type: String) -> GoalType {
            GoalType(rawValue: type) ?? .hourly
        }
    }
    
    enum Priority: String, Identifiable {
        case high
        case medium
        case low
        
        var id: String { self.rawValue }
        
        static func getRawType(from priority: String) -> Priority {
            Priority(rawValue: priority) ?? .medium
        }
    }
    
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var ownerID: String = ""
    @Persisted var creationDate: Date = .now
    
    @Persisted var label: String = ""
    @Persisted var goalDescription: String = ""
    
    @Persisted var frequency: Int = 1
    @Persisted var targetHours: Int = 0
    
    @Persisted var priority: String = ""
    @Persisted var type: String = ""
    @Persisted var targetTag: RecallCategory? = nil
    
    convenience init( ownerID: String, label: String, description: String, frequency: Int, targetHours: Int, priority: Priority, type: GoalType, targetTag: RecallCategory?) {
        self.init()
        
        self.ownerID = ownerID
        self.label = label
        self.goalDescription = description
        self.frequency = frequency
        self.targetHours = targetHours
        self.priority = priority.rawValue
        self.type = type.rawValue
        self.targetTag = targetTag
    }
    
    func update( label: String, description: String, frequency: GoalFrequence, targetHours: Int, priority: Priority, type: GoalType, targetTag: RecallCategory?) {
        
        RealmManager.updateObject(self) { thawed in
            thawed.label = label
            thawed.goalDescription = goalDescription
            thawed.frequency = frequency.numericValue
            thawed.targetHours = targetHours
            thawed.priority = priority.rawValue
            thawed.type = type.rawValue
            thawed.targetTag = targetTag
        }
    }
    
    func delete() {
        RealmManager.deleteObject(self) { goal in goal._id == self._id }
    }
    
//    MARK: Convenience Functions
    func getEncryptionKey() -> String {
        label + _id.stringValue
    }
    
    var key: String { getEncryptionKey() }
    
    static func getGoalFromKey(_ key: String) -> RecallGoal? {
        let goals: [RecallGoal] = RealmManager.retrieveObjects { goal in
            goal.getEncryptionKey() == key
        }
        return goals.first
    }
    
    @MainActor
    func getStartDate() -> Date {
        max( RecallModel.index.earliestEventDate.resetToStartOfDay(), creationDate.resetToStartOfDay() )
    }
    
    
//    MARK: Data Aggregators
    @MainActor
    func getProgressTowardsGoal(from events: [RecallCalendarEvent]) -> Int {
        
//        let isSunday = Calendar.current.component(.weekday, from: .now) == 1
//        let lastSunday = (Calendar.current.date(bySetting: .weekday, value: 1, of: .now) ?? .now) - (isSunday ? 0 : 7 * Constants.DayTime)
        
        let filtered = events.filter { event in event.startTime > Date.now.resetToStartOfDay() }
        return filtered.reduce(0) { partialResult, event in
            partialResult + Int( event.getGoalPrgress(self) )
        }
    }
    
    @MainActor
    func countGoalMet(from events : [RecallCalendarEvent]) -> (Int, Int) {
        
        let total = (Date.now.timeIntervalSince( getStartDate() ) / Constants.DayTime).rounded(.up)
        let count = events.filter { event in Int(event.getGoalPrgress(self)) >= targetHours }.count
        
        return ( count, Int(total) - count )
    }
    
    @MainActor
    func getAverage(from events: [RecallCalendarEvent]) -> (Float) {
        let rawFrequence = GoalFrequence.getRawType(from: frequency)
        let numberOfTimePeriods = Date.now.timeIntervalSince( getStartDate() ) / ( rawFrequence == .daily ? Constants.DayTime : Constants.WeekTime)
        
        let allEvents = events.reduce(0) { partialResult, event in partialResult + event.getGoalPrgress(self) }
        
        return Float(allEvents) / max(Float( numberOfTimePeriods * ( rawFrequence == .daily ? 1 : 7 ) ) , 1)
    }
}

