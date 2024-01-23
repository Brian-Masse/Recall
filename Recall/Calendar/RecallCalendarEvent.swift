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
    @Persisted var isTemplate: Bool = false
    @Persisted var isFavorite: Bool = false
    
    @Persisted var startTime: Date = .now
    @Persisted var endTime:   Date = .now + Constants.HourTime
    
    @Persisted var category: RecallCategory? = nil
    @Persisted var goalRatings: RealmSwift.List< GoalNode> = List()
    
    private var cachedGoalRatings: RealmSwift.List<GoalNode> = List()
    
//    MARK: Main
    @MainActor
    convenience init(ownerID: String, title: String, notes: String, startTime: Date, endTime: Date, categoryID: ObjectId, goalRatings: Dictionary<String, String>) {
        self.init()
        self.ownerID = ownerID
        
        self.title = title
        self.notes = notes
        self.startTime = startTime
        self.endTime = endTime
        
        if let retrievedCategory = RecallCategory.getCategoryObject(from: categoryID) { self.category = retrievedCategory }
        self.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
        
        checkUpdateEarliestEvent()
        
        updateIndex()
        updateRecentRecallEventEndTime(to: endTime)
    }

    @MainActor
    override init() {
        super.init()
        
        self.cachedGoalRatings = self.goalRatings
    }
    
    func identifier() -> String {
        ownerID + title + startTime.formatted() + endTime.formatted()
    }
    
    @MainActor
//    MARK: Updates
    func update( title: String, notes: String, startDate: Date, endDate: Date, tagID: ObjectId, goalRatings: Dictionary<String, String> ) {
        RealmManager.updateObject(self) { thawed in
            thawed.title = title
            thawed.notes = notes
            thawed.startTime = startDate
            thawed.endTime = endDate
            
            if let retrievedTag = RecallCategory.getCategoryObject(from: tagID) { thawed.category = retrievedTag }
            thawed.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
            
            updateIndex()
            updateRecentRecallEventEndTime(to: endDate)
        }
        
        checkUpdateEarliestEvent()
    }
    
    func updateDate(startDate: Date? = nil, endDate: Date? = nil) {
        RealmManager.updateObject(self) { thawed in
            thawed.startTime = startDate ?? thawed.startTime
            thawed.endTime = endDate ?? thawed.endTime
            
            updateIndex()
            updateRecentRecallEventEndTime(to: thawed.endTime)
        
        }
        
        checkUpdateEarliestEvent()
    }
    
//    unlike updateDate, which sets the event's date to that new value, this only sets the date components
//    preserving the time details
    func updateDateComponent(to date: Date) {
        let newStart = self.startTime.dateBySetting(dateFrom: date)
        let newEnd = self.endTime.dateBySetting(dateFrom: date)
        
        RealmManager.updateObject(self) { thawed in
            thawed.startTime = newStart
            thawed.endTime = newEnd
            
            updateIndex()
            
        }
        
        updateRecentRecallEventEndTime(to: newEnd)
        checkUpdateEarliestEvent()
    }
    
    func updateTag(with tag: RecallCategory) {
        RealmManager.updateObject(self) { thawed in
            thawed.category = tag
            
            updateIndex()
        }
    }
    
    @MainActor
    func updateGoalRatings(with ratings: Dictionary<String, String>) {
        let list = RecallCalendarEvent.translateGoalRatingDictionary(ratings)
        RealmManager.updateObject(self) { thawed in
            
            thawed.goalRatings = list
            
            updateIndex()
        }
    }
    
//    MARK: Convenience Functions
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
        category?.getColor() ?? RecallModel.shared.activeColor
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
    
//    When an event changes in any way (is created, updated, or deleted), it needs to quickly reindex the goalWasMet data...
    private func updateIndex() {
        Task { await RecallModel.index.updateEvent(self) }
    }
    
    private func updateRecentRecallEventEndTime(to time: Date) {
        RecallModel.index.setMostRecentRecallEvent(to: time)
    }
    
    @MainActor
    func delete(preserveTemplate: Bool = false) {
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
//            toggleTemplate()
        }
        
        updateIndex()

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

//    MARK: Layout functions
//    When calendar events are layed out on top of each other, this function detects that so they can resize their width appropriatley
//    All of the below functions handle layering and overlaps
    private func getOverlapNodes(from events: [RecallCalendarEvent]) -> [RecallCalendarEvent] {
        func checkFirstOverlap( with event: RecallCalendarEvent ) -> Bool {
            (event.startTime > self.startTime && event.startTime < self.endTime) || (event.endTime) > self.startTime && event.endTime < self.endTime
        }
        func checkSecondOverlap(with event: RecallCalendarEvent) -> Bool {
            (self.startTime > event.startTime && self.startTime < event.endTime) || (self.endTime) > event.startTime && self.endTime < event.endTime
        }
        
        return events.filter { event in
            event.startTime.matches(self.startTime, to: .day) && ( checkFirstOverlap(with: event) || checkSecondOverlap(with: event) )
        }
    }
    
    private func getWidth(from overlapData: [RecallCalendarEvent], in fullWidth: CGFloat, from events: [RecallCalendarEvent]) -> CGFloat {
        
        let overlapCount = overlapData.count
        
        var sortedOverlapCounts = overlapData.compactMap { event in event.getOverlapNodes(from: events).count }
        sortedOverlapCounts.append(overlapCount)
        sortedOverlapCounts.sort { i1, i2 in i1 > i2 }
        
        if overlapCount < sortedOverlapCounts.first ?? -1 {
            if let eventWithMaxOverlaps = overlapData.first(where: { event in event.getOverlapNodes(from: events).count == sortedOverlapCounts.first ?? 0 }) {
                return eventWithMaxOverlaps.getWidth(from: eventWithMaxOverlaps.getOverlapNodes(from: events), in: fullWidth, from: events)
            }
            return 0
            
        }else {
            let firstMatchingCount = sortedOverlapCounts.first { i in sortedOverlapCounts.countAll { f in f == i } > 1 }
            return (fullWidth - 50) / CGFloat((firstMatchingCount ?? 0) + 1)
        }
    }
    
    func getOverlapData(in fullWidth: CGFloat, from events: [RecallCalendarEvent]) -> OverlapData {
        
        let overlaps = getOverlapNodes(from: events)
        let count = overlaps.count
        let width = getWidth(from: overlaps, in: fullWidth, from: events)

        var offset: CGFloat = 0

        for event in overlaps {
            let overlapNodes = event.getOverlapNodes(from: events)
            if overlapNodes.count >= count {
                let eventWidth = event.getWidth(from: overlapNodes, in: fullWidth, from: events) + 5

                if overlapNodes.count == count {
                    offset += takesPriority(self, and: event) ? eventWidth : 0
                }
                else { offset += eventWidth }
            }
        }

//        return .init(width: fullWidth, offset: 0)
        
        return OverlapData(width: width, offset: offset)
        
        func takesPriority(_ thisEvent: RecallCalendarEvent, and otherEvent: RecallCalendarEvent) -> Bool {
            if otherEvent.startTime == thisEvent.startTime { return thisEvent.title > otherEvent.title }
            else { return thisEvent.startTime > otherEvent.startTime }
        }
    }
    
    
    
    struct OverlapData {
        let width: CGFloat
        let offset: CGFloat
    }
    
}
