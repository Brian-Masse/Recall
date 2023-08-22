//
//  EventCategory.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import RealmSwift
import SwiftUI

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
    
    @MainActor
    convenience init(ownerID: String, label: String, goalRatings: Dictionary<String, String>, color: Color) {
        self.init()
        
        self.ownerID = ownerID
        self.label = label
        
        self.setColor(with: color)
        self.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
    }
    
    enum TagUpdatingOption: String {
        case completeOverride
        case nameOnly
        case preserveCustom
    }
    
    @MainActor
    func update(label: String, goalRatings: Dictionary<String, String>, color: Color ) async {
        RealmManager.updateObject(self) { thawed in
            thawed.label = label
            thawed.setColor(with: color)
            thawed.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
        }
        
        await updateEvents(preference: .preserveCustom, newLabel: label, newRatings: goalRatings)
    }
    
//    MARK: Class Methods:
    func toggleFavorite() {
        RealmManager.updateObject(self) { thawed in
            thawed.isFavorite = !self.isFavorite
        }
    }
    
    @MainActor
    private func updateEvents(preference: TagUpdatingOption, newLabel: String, newRatings: Dictionary<String, String>) async {
        
        let filteredEvents: [RecallCalendarEvent] = RealmManager.retrieveObjects() { event in event.getTagLabel() == newLabel }
        
        let oldRatingsDic = RecallCalendarEvent.translateGoalRatingList(self.goalRatings)

        for event in filteredEvents {

            switch preference {
            case .nameOnly: return
            case .completeOverride: await completeOverride(for: event, newRatings: newRatings)
            case .preserveCustom:  await preserveCustom(for: event, oldRatings: oldRatingsDic, newRatings: newRatings)
            }

        }
        
    }
    
    private func preserveCustom(for event: RecallCalendarEvent, oldRatings: Dictionary<String, String>, newRatings: Dictionary<String, String>) async {
        
        var newGoalRatings = await event.getRatingsDictionary()

//        This handles updating the already present goal ratings
        for rating in newGoalRatings {
//            the event had a certain goalRating before it was updated, now simply give it the new value
//            this handles changing the goal multiplier, as well as removing a goal rating alltogether
//            checking to make sure the old rating and the event have the same value means that custom multipliers will be preserved
            if oldRatings[rating.key] == rating.value {
                newGoalRatings[ rating.key ] = newRatings[ rating.key ]
            }
        }
        
//        this handles adding new ones, as long as they don't override custom preferences
        for rating in newRatings {
//            if the new rating has the same rating as the oldRatings, then that case should be handled above
//            Handling it here may cause it to add a rating to an event that customly chose not to include a certain rating
//            thus only ratings new to the tag will be added to the event
            if oldRatings[rating.key] == nil {
                newGoalRatings[rating.key] = rating.value
            }
        }
        
        await event.updateGoalRatings(with: newGoalRatings)
    }
    
    private func completeOverride(for event: RecallCalendarEvent, newRatings: Dictionary<String, String>) async {
        await event.updateGoalRatings(with: newRatings)
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
    
    func worksTowards(goal: RecallGoal) -> Bool {
        self.goalRatings.contains { node in
            node.key == goal.key
        }
    }
}

