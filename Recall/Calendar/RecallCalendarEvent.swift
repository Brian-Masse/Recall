//
//  CalendarComponent.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift
import SwiftUI

class RecallCalendarEvent: Object, Identifiable  {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted var title: String = ""
    @Persisted var notes: String = ""
    @Persisted var isTemplate: Bool = false
    
    @Persisted var startTime: Date = .now
    @Persisted var endTime:   Date = .now + Constants.HourTime
    
    @Persisted var category: RecallCategory? = nil
    @Persisted var goalRatings: RealmSwift.List< GoalNode> = List()
    
//    MARK: Main
    @MainActor
    convenience init(ownerID: String, title: String, startTime: Date, endTime: Date, categoryID: ObjectId, goalRatings: Dictionary<String, String>) {
        self.init()
        self.ownerID = ownerID
        
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        
        if let retrievedCategory = RecallCategory.getCategoryObject(from: categoryID) { self.category = retrievedCategory }
        self.goalRatings = RecallCalendarEvent.translateGoalRatingDictionary(goalRatings)
        
        checkUpdateEarliestEvent()
    }
    
    func identifier() -> String {
        ownerID + title + startTime.formatted() + endTime.formatted()
    }
    
    func update( title: String, startDate: Date, endDate: Date ) {
        RealmManager.updateObject(self) { thawed in
            thawed.title = title
            
            thawed.startTime = startDate
            thawed.endTime = endDate
        }
        
        checkUpdateEarliestEvent()
    }
    
    func updateDate(startDate: Date? = nil, endDate: Date? = nil) {
        RealmManager.updateObject(self) { thawed in
            thawed.startTime = startDate ?? thawed.startTime
            thawed.endTime = endDate ?? thawed.endTime
        }
    }
    
//    MARK: Convenience Functions
    
    @MainActor
    static func translateGoalRatingDictionary(_ dictionary: Dictionary<String, String>) -> RealmSwift.List<GoalNode> {
        let list: RealmSwift.List<GoalNode> = List()
        list.append(objectsIn: dictionary.map { (key: String, data: String) in
            GoalNode(ownerID: RecallModel.ownerID, key: key, data: data)
        })
        return list
    }
    
    @MainActor
    static func translateGoalRatingList( _ list: RealmSwift.List<GoalNode> ) -> Dictionary<String, String> {
        var dic = Dictionary<String, String>()
        for node in list { dic[node.key] = node.data }
        return dic
    }
    
//    This can later be modified to ensure only a select number of events are pulled from the server onto the device
    static func getEvents(where query: ( (RecallCalendarEvent) -> Bool )? = nil) -> [RecallCalendarEvent] {
        RealmManager.retrieveObjects(where: query)
    }
    
    func getColor() -> Color {
        category?.getColor() ?? Colors.tint
    }
    
    
//    MARK: Class Methods
    func delete() {
        RealmManager.deleteObject(self) { event in event._id == self._id }
    }
    
    private func checkUpdateEarliestEvent() {
        if self.startTime < RecallModel.realmManager.index.earliestEventDate {
            RecallModel.realmManager.index.updateEarliestEventDate(with: self.startTime)
        }
    }

    func getLengthInHours() -> Double {
        endTime.timeIntervalSince(startTime) / Constants.HourTime
    }
    
//    This checks to see if this event has a multiplier for a specifc goal (ie. coding should have 'productive')
    func getGoalMultiplier(from goal: RecallGoal) -> Double {
        let key = goal.getEncryptionKey()
        let data = self.goalRatings.first { node in node.key == key }?.data ?? "0"
        return Double(data) ?? 0
    }
    
    func getGoalPrgress(_ goal: RecallGoal) -> Double {
        getLengthInHours() * getGoalMultiplier(from: goal)
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
                
                if overlapNodes.count == count { offset += event.startTime < self.startTime ? eventWidth : 0 }
                else { offset += eventWidth }
            }
        }
    
        return OverlapData(width: width, offset: offset)
    }
    
    
    struct OverlapData {
        let width: CGFloat
        let offset: CGFloat
    }
    
}
