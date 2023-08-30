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
class GoalNode: Object, Identifiable, OwnedRealmObject {
   
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
class RecallGoal: Object, Identifiable, OwnedRealmObject {
    
    
//    MARK: Enums
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
    
    enum Priority: String, Identifiable, CaseIterable {
        case high
        case medium
        case low
        
        var id: String { self.rawValue }
        
        static func getRawType(from priority: String) -> Priority {
            Priority(rawValue: priority) ?? .medium
        }
    }
//    MARK: Body
    
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
    
//    This overrideKey has a very specific purpose, and does not need to be used in general use of the app
//    If there is an issue with sync, and data needs to be manually reinserted into the synced realm from a local realm file
//    the objectIDs of everything will be overriden / changed. This is fine for most objects, however goals use their object ids
//    to match with GoalNodes which are used for goalRatings.
//    The overrrideKey is a place to store (from the DB) the previous objectID, and use in encryption key funcs instead
    @Persisted var overrideKey: String? = nil
    
    convenience init( ownerID: String, label: String, description: String, frequency: Int, targetHours: Int, priority: Priority, type: GoalType, targetTag: RecallCategory?) {
        self.init()
        
        self.ownerID = ownerID
        self.label = label
        self.goalDescription = description
        self.frequency = frequency
        self.targetHours = targetHours
        self.priority = priority.rawValue
        self.type = type.rawValue
                
        if let id = targetTag?._id {
            if let retrievedTag = RecallCategory.getCategoryObject(from: id) { self.targetTag = retrievedTag }
        }
    }
    
    func update( label: String, description: String, frequency: GoalFrequence, targetHours: Int, priority: Priority, type: GoalType, targetTag: RecallCategory?, creationDate: Date) {
        
        RealmManager.updateObject(self) { thawed in
            thawed.label = label
            thawed.goalDescription = description
            thawed.frequency = frequency.numericValue
            thawed.targetHours = targetHours
            thawed.priority = priority.rawValue
            thawed.type = type.rawValue
            thawed.creationDate = creationDate
            
            if let id = targetTag?._id {
                if let retrievedTag = RecallCategory.getCategoryObject(from: id) { thawed.targetTag = retrievedTag }
            }
        }
    }
    
    func delete() {
        RealmManager.deleteObject(self) { goal in goal._id == self._id }
    }
    
//    MARK: Convenience Functions
    func getEncryptionKey() -> String {
        label + ( overrideKey ?? _id.stringValue)  
    }
    
    var key: String { getEncryptionKey() }
    
    @MainActor
    static func getGoalFromKey(_ key: String) -> RecallGoal? {
        let goals: [RecallGoal] = RealmManager.retrieveObjects { goal in
            goal.getEncryptionKey() == key
        }
        return goals.first
    }
    
    @MainActor
    func getStartDate() -> Date {
        max( RecallModel.getEarliestEventDate().resetToStartOfDay(), creationDate.resetToStartOfDay() )
    }
    
//    This tells how many times you could have met the goal since creation (differs based on week vs day)
    @MainActor
    func getNumberOfTimePeriods() -> Double {
        let rawFrequence = GoalFrequence.getRawType(from: frequency)
        return Date.now.timeIntervalSince( getStartDate() ) / ( rawFrequence == .daily ? Constants.DayTime : Constants.WeekTime)
    }
    
//    @MainActor
    func goalWasMet(on date: Date, events: [RecallCalendarEvent]) async -> Bool {
        await Double(self.getProgressTowardsGoal(from: events, on: date )) >= Double(targetHours)
    }
    
    func byTag() -> Bool {
        GoalType.getRawType(from: self.type) == .byTag
    }
    
    
//    MARK: Data Aggregators
    
    func getProgressTowardsGoal(from events: [RecallCalendarEvent], on date: Date = .now) async -> Double {
        
        let step = RecallGoal.GoalFrequence.getRawType(from: self.frequency) == .weekly ? 7 * Constants.DayTime : Constants.DayTime
        
        let isSunday = Calendar.current.component(.weekday, from: date) == 1
        let lastSunday = (Calendar.current.date(bySetting: .weekday, value: 1, of: date) ?? date) - (isSunday ? 0 : 7 * Constants.DayTime)
        let startDate = RecallGoal.GoalFrequence.getRawType(from: self.frequency) == .weekly ? lastSunday : date
        
        let filtered = events.filter { event in event.startTime > startDate.resetToStartOfDay() && event.endTime < (startDate + step) }
        return filtered.reduce(0) { partialResult, event in
            partialResult + event.getGoalPrgress(self)
        }
    }
    
//    First int is how many times you've hit the goal, the second is how many times you've missed it
//    @MainActor
    func countGoalMet(from events : [RecallCalendarEvent]) async -> (Int, Int) {
        
        let step = self.frequency == RecallGoal.GoalFrequence.weekly.numericValue ? Constants.WeekTime : Constants.DayTime
        var dateIterator = await self.getStartDate()
        var metCount = 0
        
        while dateIterator <= .now {
            let endDate = dateIterator + step
            let count = events.filter { event in event.startTime > dateIterator && event.startTime < endDate }.reduce(0) { partialResult, event in
                partialResult + event.getGoalPrgress(self)
            }
            metCount += (count >= Double(targetHours) ? 1 : 0)
            dateIterator += step
        }

        let numberOfTimePeriods = await getNumberOfTimePeriods()
        
        return(metCount, Int(numberOfTimePeriods.rounded(.up)) - metCount)
    }
    
//    @MainActor
    func getAverage(from events: [RecallCalendarEvent]) async -> Double {
        let numberOfTimePeriods = await getNumberOfTimePeriods()
        
        let allEvents = events.reduce(0) { partialResult, event in partialResult + event.getGoalPrgress(self) }
        
        return allEvents / max(Double(numberOfTimePeriods) * Double(frequency) , 1)
    }
}
