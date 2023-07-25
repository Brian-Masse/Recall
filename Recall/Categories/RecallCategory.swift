//
//  EventCategory.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import RealmSwift
import SwiftUI

class RecallCategory: Object, Identifiable {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var ownerID: String  = ""
    
    @Persisted var label: String    = ""
    @Persisted var productivity: Float = 0 //This does not do anything, and should be deleted, thats just a whole process with the scheme and I don't feel like doing it
    @Persisted var isFavorite: Bool = false
    
    @Persisted var r: Double = 0
    @Persisted var g: Double = 0
    @Persisted var b: Double = 0
    
    @Persisted var goalRatings: RealmSwift.List<GoalNode> = List()
    
    @MainActor
    convenience init(ownerID: String, label: String, goalRatings: Dictionary<String, String>, color: Color) {
        self.init()
        
        self.ownerID = ownerID
        self.label = label
        
        self.setColor(with: color)
        self.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
    }
    
    @MainActor
    func update(label: String, goalRatings: Dictionary<String, String>, color: Color ) {
        RealmManager.updateObject(self) { thawed in
            thawed.label = label            
            thawed.setColor(with: color)
            thawed.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
        }
    }
    
//    MARK: Class Methods:
    func toggleFavorite() {
        RealmManager.updateObject(self) { thawed in
            thawed.isFavorite = true
        }
    }
    
//    MARK: Convenience Functions
    static func getCategoryObject(from id: ObjectId) -> RecallCategory? {
        let results: Results<RecallCategory> = RealmManager.retrieveObject { query in query._id == id }
        guard let first = results.first else { print("no Category exists with given id: \(id.stringValue)"); return nil }
        return first
    }
    
    func setColor(with color: Color) {
        let comps = color.components
        self.r = comps.red
        self.g = comps.green
        self.b = comps.blue
    }
    
    func getColor() -> Color {
        Color(red: r, green: g, blue: b)
    }
    
    func delete() {
        RealmManager.deleteObject(self) { category in
            category._id == self._id
        }
    }

}
