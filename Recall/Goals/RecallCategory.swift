//
//  EventCategory.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import RealmSwift

class RecallCategory: Object, Identifiable {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var ownerID: String  = ""
    
    @Persisted var label: String    = ""
    @Persisted var productivity: Float = 0      //This does not do anything, and should be deleted, thats just a whole process with the scheme and I don't feel like doing it
    
    @Persisted var goalRatings: List<GoalNode> = List()
    
    @MainActor
    convenience init(ownerID: String, label: String, goalRatings: Dictionary<String, String>) {
        self.init()
        
        self.ownerID = ownerID
        self.label = label
        
        self.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
    }
    
//    MARK: Convenience Functions
    static func getCategoryObject(from id: ObjectId) -> RecallCategory? {
        let results: Results<RecallCategory> = RealmManager.retrieveObject { query in query._id == id }
        guard let first = results.first else { print("no Category exists with given id: \(id.stringValue)"); return nil }
        return first
    }

}
