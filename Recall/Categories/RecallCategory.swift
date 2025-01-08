//
//  EventCategory.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import RealmSwift
import SwiftUI

//MARK: RecallCategoryStore

class RecallCategoryStore {
    static let shared = RecallCategoryStore()
    
    private var tagColors: [String: Color] = [:]
    
    func getColor( for tag: RecallCategory ) -> Color {
        if let color = tagColors[tag.label] { return color }
        let color = Color(red: tag.r, green: tag.g, blue: tag.b)
        
        self.tagColors[tag.label] = color
        return color
    }
    
    func updateColor(for tag: RecallCategory, color: Color) {
        self.tagColors[tag.label] = color
    }
}

//MARK: - RecallCategory
class RecallCategory: Object, Identifiable, OwnedRealmObject {

    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var ownerID: String  = ""
    
    @Persisted var label: String    = ""
    @Persisted var productivity: Float = 0 //This does not do anything, and should be deleted, thats just a whole process with the scheme and I don't feel like doing it
    @Persisted var isFavorite: Bool = false
    
    @Persisted var r: Double = 0
    @Persisted var g: Double = 0
    @Persisted var b: Double = 0
    
    @Persisted var goalRatings: RealmSwift.List<GoalNode> = List()
    
//    MARK: Init
    @MainActor
    convenience init(ownerID: String, label: String, goalRatings: Dictionary<String, String>, color: Color, previewTag: Bool = false) {
        self.init()
        
        self.ownerID = ownerID
        self.label = label
        self.updateColor(with: color)
        
        if !previewTag {
            self.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
        }
    }
    
//    MARK: - Update
    @MainActor
    func update(label: String, goalRatings: Dictionary<String, String>, color: Color ) async {
        
        let newGoalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
        if newGoalRatings != self.goalRatings {
            self.updateGoalRatings(with: newGoalRatings)
        }
        
        RealmManager.updateObject(self) { thawed in
            thawed.label = label
            thawed.updateColor(with: color)
        }
    }
    
//    MARK: UpdateGoalRatings
    @MainActor
    private func updateGoalRatings(with list: RealmSwift.List<GoalNode>) {
        RealmManager.updateObject(self) { thawed in
            thawed.goalRatings = list
        }
        
//        await event.updateGoalRatings(with: newGoalRatings)
    }
    
//    MARK: UpdateColor
    @MainActor
    private func updateColor(with color: Color) {
        let components = color.components
        self.r = components.red
        self.g = components.green
        self.b = components.blue
        
        RecallCategoryStore.shared.updateColor(for: self, color: color)
    }
    
//    MARK: ToggleFavorite
    @MainActor
    func toggleFavorite() {
        RealmManager.updateObject(self) { thawed in
            thawed.isFavorite = !self.isFavorite
        }
    }
    
//    MARK: Convenience Functions
    @MainActor
    static func getCategoryObject(from id: ObjectId) -> RecallCategory? {
        let results: Results<RecallCategory> = RealmManager.retrieveObjectsInResults { query in query._id == id }
        guard let first = results.first else { print("no Category exists with given id: \(id.stringValue)"); return nil }
        return first
    }
    
    var color: Color? = nil
    
    func getColor() -> Color {
        RecallCategoryStore.shared.getColor(for: self)
    }
    
    @MainActor
    func delete() {
        RealmManager.deleteObject(self) { category in
            category._id == self._id
        }
    }
    
    func worksTowards(goal: RecallGoal) -> Bool {
        self.goalRatings.contains { node in
            node.key == goal.key
        }
    }
}

