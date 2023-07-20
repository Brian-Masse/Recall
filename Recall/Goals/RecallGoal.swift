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
        
        var id: String {
            self.rawValue
        }
    }
    
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var ownerID: String = ""
    
    @Persisted var label: String = ""
    @Persisted var frequency: Int = 1
    @Persisted var targetHours: Int = 0
    
    convenience init( ownerID: String, label: String, frequency: Int, targetHours: Int ) {
        self.init()
        
        self.ownerID = ownerID
        self.label = label
        self.frequency = frequency
        self.targetHours = targetHours
    }
    
//    MARK: Convenience Functions
    func getEncryptionKey() -> String {
        label + _id.stringValue
    }
    
    
//    MARK: Data Aggregators
    func getCurrentProgressTowardsGoal() -> CGFloat {
       
        let isSunday = Calendar.current.component(.weekday, from: .now) == 1
        let lastSunday = (Calendar.current.date(bySetting: .weekday, value: 1, of: .now) ?? .now) - (isSunday ? 0 : 7 * Constants.DayTime)
        
        let objects: [RecallCalendarEvent] = RealmManager.retrieveObjects { event in event.startTime > lastSunday }
        let aggregateRatings = objects.reduce(0) { partialResult, event in
            if let ratingNode = event.goalRatings.first(where: { node in node.key == self.getEncryptionKey() }) {
                return partialResult + (Int(ratingNode.data) ?? 0)
            }
            return partialResult
        }
        
        return CGFloat(aggregateRatings) / CGFloat(self.targetHours)
        
    }
    
}
