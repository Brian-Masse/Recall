//
//  RecallCalendarEvent.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift
import SwiftUI
import UIUniversals

class RecallCalendarEvent: Object, Identifiable, OwnedRealmObject  {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted var title: String = ""
    @Persisted var notes: String = ""
    @Persisted var urlString: String = ""
    
    @Persisted var locationLongitude: Double = 0
    @Persisted var locationLatitude: Double = 0
    @Persisted var locationTitle: String = ""
    
    @Persisted var isTemplate: Bool = false
    @Persisted var isFavorite: Bool = false
    
    @Persisted var startTime: Date = .now
    @Persisted var endTime:   Date = .now + Constants.HourTime
    
    @Persisted var category: RecallCategory? = nil
    @Persisted var goalRatings: RealmSwift.List< GoalNode> = List()
    
    private var cachedGoalRatings: RealmSwift.List<GoalNode> = List()
    
//    MARK: Main
    @MainActor
    convenience init(ownerID: String,
                     title: String,
                     notes: String,
                     urlString: String,
                     location: LocationResult? = nil,
                     startTime: Date,
                     endTime: Date,
                     categoryID: ObjectId,
                     goalRatings: Dictionary<String, String>,
                     previewEvent: Bool = false) {
        self.init()
        self.ownerID = ownerID
        
        self.title = title
        self.notes = notes
        self.urlString = urlString
        
        self.startTime = startTime
        self.endTime = endTime
        
        if let location = location {
            self.locationTitle = location.title
            self.locationLongitude = location.location.longitude
            self.locationLatitude = location.location.latitude
        }
        
        if !previewEvent {
            if let retrievedCategory = RecallCategory.getCategoryObject(from: categoryID) { self.category = retrievedCategory }
            self.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
        
            checkUpdateEarliestEvent()
            
            RecallModel.shared.updateEvent(self)
            updateRecentRecallEventEndTime(to: endTime)
        }
    }

    @MainActor
    override init() {
        super.init()
        self.cachedGoalRatings = self.goalRatings
    }
    
    func identifier() -> String { ownerID + title + startTime.formatted() + endTime.formatted() }
    
    @MainActor
//    MARK: Updates
    func update( title: String,
                 notes: String,
                 urlString: String,
                 startDate: Date,
                 endDate: Date,
                 location: LocationResult? = nil,
                 tagID: ObjectId,
                 goalRatings: Dictionary<String, String> ) {
        if !self.startTime.matches(startDate, to: .day) { RecallModel.index.updateEventsIndex(oldDate: self.startTime, newDate: startDate) }
        
        RealmManager.updateObject(self) { thawed in
            thawed.title = title
            thawed.notes = notes
            thawed.urlString = urlString
            thawed.startTime = startDate
            thawed.endTime = endDate
            
            if let location = location {
                thawed.locationTitle = location.title
                thawed.locationLongitude = location.location.longitude
                thawed.locationLatitude = location.location.latitude
            }
            
            if let retrievedTag = RecallCategory.getCategoryObject(from: tagID) { thawed.category = retrievedTag }
            thawed.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
            
            RecallModel.shared.updateEvent(thawed)
            updateRecentRecallEventEndTime(to: endDate)
        }
        
        RecallModel.index.addEventToIndex(on: startDate)
        
        checkUpdateEarliestEvent()
    }
    
    @MainActor
    func updateDate(startDate: Date? = nil, endDate: Date? = nil) {
        if let startDate {
            if !self.startTime.matches(startDate, to: .day) { RecallModel.index.updateEventsIndex(oldDate: self.startTime, newDate: startDate) }
        }
        
        RealmManager.updateObject(self) { thawed in
            thawed.startTime = startDate ?? thawed.startTime
            thawed.endTime = endDate ?? thawed.endTime
            
            RecallModel.shared.updateEvent(thawed)
            updateRecentRecallEventEndTime(to: thawed.endTime)
        
        }
        
        checkUpdateEarliestEvent()
    }
    
//    unlike updateDate, which sets the event's date to that new value, this only sets the date components
//    preserving the time details
    @MainActor
    func updateDateComponent(to date: Date) {
        let newStart = self.startTime.dateBySetting(dateFrom: date)
        let newEnd = self.endTime.dateBySetting(dateFrom: date)
        
        if !self.startTime.matches(newStart, to: .day) { RecallModel.index.updateEventsIndex(oldDate: self.startTime, newDate: newStart) }
        
        RealmManager.updateObject(self) { thawed in
            thawed.startTime = newStart
            thawed.endTime = newEnd
            
            RecallModel.shared.updateEvent(thawed)
            
        }
        
        updateRecentRecallEventEndTime(to: newEnd)
        checkUpdateEarliestEvent()
    }
    
    func updateTag(with tag: RecallCategory) {
        RealmManager.updateObject(self) { thawed in
            thawed.category = tag
            
            RecallModel.shared.updateEvent(thawed)
        }
    }
    
    @MainActor
    func updateGoalRatings(with ratings: Dictionary<String, String>) {
        let list = RecallCalendarEvent.translateGoalRatingDictionary(ratings)
        RealmManager.updateObject(self) { thawed in
            
            thawed.goalRatings = list
            
            RecallModel.shared.updateEvent(thawed)
        }
    }
    
//    MARK: Convenience Functions
    func getURL() -> URL? {
        URL(string: self.urlString)
    }
    
    @MainActor
    func getRatingsDictionary() -> Dictionary<String,String> {
        RecallCalendarEvent.translateGoalRatingList(self.goalRatings)
    }

    static func translateGoalRatingDictionary(_ dictionary: Dictionary<String, String>) -> RealmSwift.List<GoalNode> {
        let list: RealmSwift.List<GoalNode> = List()
        list.append(objectsIn: dictionary.map { (key: String, data: String) in
            GoalNode(ownerID: RecallModel.ownerID, key: key, data: data)
        })
        return list
    }
    
    static func translateGoalRatingList( _ list: RealmSwift.List<GoalNode> ) -> Dictionary<String, String> {
        var dic = Dictionary<String, String>()
        for node in list { dic[node.key] = node.data }
        return dic
    }
    
//    This can later be modified to ensure only a select number of events are pulled from the server onto the device
    @MainActor
    static func getEvents(where query: ( (RecallCalendarEvent) -> Bool )? = nil) -> [RecallCalendarEvent] {
        RealmManager.retrieveObjects(where: query)
    }
    
    @MainActor
    func getColor() -> Color {
        category?.getColor() ?? Colors.defaultLightAccent
    }
    
    func getTagLabel() -> String {
        category?.label ?? "?"
    }
    
    @MainActor
    func toggleTemplate() {
        RealmManager.updateObject(self) { thawed in
            thawed.isTemplate = !self.isTemplate
        }
    }
    
    @MainActor
    func toggleFavorite() {
        RealmManager.updateObject(self) { thawed in
            thawed.isFavorite = !self.isFavorite
        }
    }
    
//    This is a list of all the goals this event's tag contributes to
    @MainActor
    func getGoals() -> [RecallGoal] {
        self.goalRatings.compactMap { node in
            if node.getNumericData() > 0 {
                if let goal = RecallGoal.getGoalFromKey(node.key) {
                    return goal
                }
            }
            return nil
        }
    }
    
//    MARK: Class Methods

    private func updateRecentRecallEventEndTime(to time: Date) {
        RecallModel.index.setMostRecentRecallEvent(to: time)
    }
    
    @MainActor
    func delete(preserveTemplate: Bool = false) {
        RecallModel.index.removeEventFromIndex(on: self.startTime)
        
        if !preserveTemplate {
            if self.isTemplate { self.toggleTemplate() }
            RealmManager.deleteObject(self) { event in event._id == self._id }
        }
        
        else {
//            toggleTemplate()
            var components = DateComponents()
            components.year = 2005
            components.month = 5
            components.day = 18
            let newDate = Calendar.current.date(from: components)
            
            let startComponents  = Calendar.current.dateComponents([.minute, .hour], from: startTime)
            let endComponents    = Calendar.current.dateComponents([.minute, .hour], from: endTime)
            
            let startDate = Calendar.current.date(bySettingHour: startComponents.hour!, minute: startComponents.minute!, second: 0, of: newDate!)
            let endDate   = Calendar.current.date(bySettingHour: endComponents.hour!, minute: endComponents.minute!, second: 0, of: newDate!)
            
            updateDate(startDate: startDate, endDate: endDate)
        }
        
        RecallModel.shared.updateEvent(self)

    }
    
    private func checkUpdateEarliestEvent() {
        
        if Calendar.current.component(.year, from: self.startTime) == 2005 { return }
        if self.startTime < RecallModel.realmManager.index.earliestEventDate {
            RecallModel.realmManager.index.updateEarliestEventDate(with: self.startTime)
        }
    }

    func getLengthInHours() -> Double {
        endTime.timeIntervalSince(startTime) / Constants.HourTime
    }
    
//    This checks to see if this event has a multiplier for a specifc goal (ie. coding should have 'productive')
    @MainActor
    private func getGoalMultiplier(from goal: RecallGoal) -> Double {
        let key = goal.getEncryptionKey()
        let data = goalRatings.first { node in node.key == key }?.data ?? "0"
        return Double(data) ?? 0
    }
    
    func getGoalPrgress(_ goal: RecallGoal) async -> Double {
        let multiplier = await getGoalMultiplier(from: goal)
        if RecallGoal.GoalType.getRawType(from: goal.type) == .hourly { return getLengthInHours() * multiplier }
        else if goal.targetTag?.label ?? "" == self.category?.label ?? "-" { return 1 }
        return 0
    }
    
//    to avoid certain crashes the standard 'getGoalMultiplier' should mostly be run on the main thread
//    however, there are certain cases where its technically difficult to do so, 
//    but will not elicit a crash to run it on any thread
//    for those cases, run this function, it does the same work as 'getGoalProgress' but on any thread
    func getGoalProgressThreadInvariant( _ goal: RecallGoal ) -> Double {
        let key = goal.getEncryptionKey()
        let data = goalRatings.first { node in node.key == key }?.data ?? "0"
        let multiplier = Double(data) ?? 0
        
        if RecallGoal.GoalType.getRawType(from: goal.type) == .hourly { return getLengthInHours() * multiplier }
        else if goal.targetTag?.label ?? "" == self.category?.label ?? "-" { return 1 }
        return 0
    }
}


//MARK: SampleEvent
@MainActor
let sampleEvent = RecallCalendarEvent(ownerID: "",
                                    title: "test event",
                                    notes: "Its been a long long time. A moment to shine, shine, shine, shine, shinnnnnnnnnneeeeee. Ooooh ohh",
                                    urlString: "https://github.com/Brian-Masse/Recall",
                                    startTime: .now,
                                    endTime: .now + Constants.HourTime * 2,
                                          categoryID: ObjectId(),
                                    goalRatings: [:],
                                    previewEvent: true)
