//
//  CalendarComponent.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift

//class RecallCalendar: Object {
//
//    @Persisted(primaryKey: true) var _id: ObjectId
//    @Persisted var ownerID: String
//
//}

class RecallCalendarEvent: Object, Identifiable  {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted var title: String = ""
    
    @Persisted var startTime: Date = .now
    @Persisted var endTime:   Date = .now + Constants.HourTime
    
    @Persisted var category: RecallCategory? = nil
    @Persisted var goalRatings: List< GoalNode> = List()
    
    @MainActor
    convenience init(ownerID: String, title: String, startTime: Date, endTime: Date, categoryID: ObjectId, goalRatings: Dictionary<String, String>) {
        self.init()
        self.ownerID = ownerID
        
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        
        if let retrievedCategory = RecallCategory.getCategoryObject(from: categoryID) { self.category = retrievedCategory }
        self.goalRatings = translateGoalRatingDictionary(goalRatings)
        
        
    }
    
    func update( title: String, startDate: Date, endDate: Date ) {
        RealmManager.updateObject(self) { thawed in
            thawed.title = title
            
            thawed.startTime = startDate
            thawed.endTime = endDate
        }
    }
    
    func updateDate(startDate: Date? = nil, endDate: Date? = nil) {
        RealmManager.updateObject(self) { thawed in
            thawed.startTime = startDate ?? thawed.startTime
            thawed.endTime = endDate ?? thawed.endTime
        }
    }
    
//    MARK: Class Methods
    
    func delete() {
        RealmManager.deleteObject(self) { event in event._id == self._id }
    }
    
    @MainActor
    private func translateGoalRatingDictionary(_ dictionary: Dictionary<String, String>) -> List<GoalNode> {
        let list: List<GoalNode> = List()
        list.append(objectsIn: dictionary.map { (key: String, data: String) in
            GoalNode(ownerID: RecallModel.ownerID, key: key, data: data)
        })
        return list
    }
    
}

