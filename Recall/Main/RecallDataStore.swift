//
//  RecallDataStore.swift
//  Recall-WidgetExtension
//
//  Created by Brian Masse on 12/14/24.
//

import Foundation
import RealmSwift
import WidgetKit
import UIUniversals

class RecallDataStore: Object {
    
//    MARK: Vars
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
//    MARK: - ManageWidgets
//    take the stored values in this class, and write them into the shared UserDefaults
//    This will be run a lot (namely any time an event is created / updated)
    @MainActor
    func writeAllWidgetDataToStore() {
        writeMostRecentFavoriteEventToStore()
        writeAllFavoriteEventsToStore()
        writeCurrentMonthLogToStore()
        writeTodaysEventsToStore()
    }
    
//    each individual writeXXXToStore is basically just a flush function
//    whatever the value stored in the dataStore is gets written to the UserDefaults
//    meaning that it is up to other parts of the code to correctly update the data in the store
    @MainActor
    private func writeMostRecentFavoriteEventToStore() {
        if let mostRecentFavoriteEvent = getMostRecentFavoriteEvent() {
            let widgetEvent = mostRecentFavoriteEvent.createWidgetEvent()
            WidgetStorage.shared.saveEvent(widgetEvent,
                                           for: WidgetStorageKeys.recentFavoriteEvent,
                                           timelineKind: .mostRecentFavoriteEvent)
        }
    }
    
    @MainActor
    private func writeAllFavoriteEventsToStore() {
        let events: [RecallCalendarEvent] = RealmManager.retrieveObjectsInList()
        
        let widgetEvents: [RecallWidgetCalendarEvent] = events
            .filter { $0.isFavorite }
            .map { $0.createWidgetEvent() }
        
        WidgetStorage.shared.saveEvents(widgetEvents,
                                        for: WidgetStorageKeys.favoriteEvents,
                                        timelineKind: .mostRecentFavoriteEvent)
    }
    
    @MainActor
    private func writeTodaysEventsToStore() {
        let events: [RecallCalendarEvent] = RealmManager.retrieveObjectsInList()
        let widgetEvents: [RecallWidgetCalendarEvent] = events
            .filter { $0.startTime.matches(.now - 1 * Constants.DayTime, to: .day) }
            .sorted { $0.startTime < $1.startTime }
            .filter { Calendar.current.component(.hour, from: $0.startTime) > 5 }
            .map { $0.createWidgetEvent() }
        
        WidgetStorage.shared.saveEvents(widgetEvents,
                                        for: WidgetStorageKeys.todaysEvents,
                                        timelineKind: .todaysEvents)
    }
    
    @MainActor
    private func writeCurrentMonthLogToStore() {
        let log = Array(self.currentMonthLog)
        
        WidgetStorage.shared.saveList(log,
                                      for: WidgetStorageKeys.currentMonthLog,
                                      timelineKind: .monthlyLog)
    }
    
//    MARK: - Initialize
//    This function goes through the stored properties of the data store, and for those that are null,
//    computes them. It then flushses all of them to the UserDefaults to be used by the widgets
//    This is run to make sure all values are properly initialized, and that they are accessible to widgets
    @MainActor
    func initalizeDataStore() async {
//        mostRecentFavorite
        if self.mostRecentFavoriteEventId == nil {
            await setMostRecentFavoriteEvent()
        }
        
//        monthlyLog
        if self.currentMonthLog.isEmpty || !Date.now.matches(lastUpdatedMonth, to: .month) {
            await setCurrentMonthLog()
        }
        
        self.writeAllWidgetDataToStore()
    }
    
//    MARK: - mostRecentFavoriteWidget
    @Persisted var mostRecentFavoriteEventId: ObjectId? = nil
    
    @MainActor
    func getMostRecentFavoriteEvent() -> RecallCalendarEvent? {
        if mostRecentFavoriteEventId == nil { return nil }
        return RecallCalendarEvent.getRecallCalendarEvent(from: mostRecentFavoriteEventId!)
    }
    
//    MARK: updateMostRecentEvent
    @MainActor
    private func updateMostRecentEvent(with mostRecentFavoriteEvent: RecallCalendarEvent) {
        RealmManager.updateObject(self) { thawed in
            thawed.mostRecentFavoriteEventId = mostRecentFavoriteEvent._id
        }
        
        writeMostRecentFavoriteEventToStore()
    }
    
//    MARK: setMostRecentFavoriteEvent
//    find the most recent favorite event
    @MainActor
    private func setMostRecentFavoriteEvent() async {
        let results: [RecallCalendarEvent] = RealmManager.retrieveObjectsInList()
        
        let filteredResults = results
            .filter { $0.isFavorite }
            .sorted { $0.startTime > $1.startTime }
        
        if let mostRecentFavoriteEvent = filteredResults.first {
            updateMostRecentEvent(with: mostRecentFavoriteEvent)
        }
    }
    
//    MARK: checkMostRecentFavoriteEvent
//    when an event's favorite status changes, check whether it is now the mot recent favorite event
    @MainActor
    func checkMostRecentFavoriteEvent(against event: RecallCalendarEvent, isFavorite: Bool) {
        if isFavorite {
            let mostRecentEvent = getMostRecentFavoriteEvent()
            if event.startTime > mostRecentEvent?.startTime ?? .distantPast {
                updateMostRecentEvent(with: event)
            }
        } else {
            Task { await setMostRecentFavoriteEvent() }
        }
        
        writeAllFavoriteEventsToStore()
    }
    
//    MARK: - currentMonthLogWidget
//    This is a 31 long integer list that indicates how many recalls were done on a certain day
    @Persisted var currentMonthLog: List<Int> = List()
//    This indicates the last time the currentMonthLog was updated. Each month it needs to be recomputed
    @Persisted var lastUpdatedMonth: Date = .now
    
    @MainActor
    private func updateCurrrentMonthLog(with arr: [Int]) {
        let list: List<Int> = List()
        list.append(objectsIn: arr)
        
        RealmManager.updateObject(self) { thawed in
            thawed.currentMonthLog = list
        }
        writeCurrentMonthLogToStore()
    }
    
    @MainActor
    private func updateLastUpedatedMonth(with date: Date) {
        RealmManager.updateObject(self) { thawed in
            thawed.lastUpdatedMonth = date
        }
    }
    
//    MARK: setCurrentMonthLog
//    go through each event over the past month, and tally its contribution on each day
    @MainActor
    private func setCurrentMonthLog() async {
        var currentMonthLog = [Int](repeating: 0, count: 31)
        
        let startOfMonth = Date.now.getStartOfMonth()
        
        let results: [RecallCalendarEvent] = RealmManager.retrieveObjectsInList()
        let filteredResults = results
            .filter { $0 .startTime > startOfMonth }
        
        for event in filteredResults {
            let i = floor(event.startTime.timeIntervalSince(startOfMonth) / Constants.DayTime)
            currentMonthLog[min(Int(i), 30)] += 1
            
            if i > 31 {
                print("go")
            }
        }
        
        if currentMonthLog != Array(self.currentMonthLog) {
            updateCurrrentMonthLog(with: currentMonthLog)
        }
    }
    
//    MARK: insertOrRemoveEventFromMonthLog
//    If an even is created or deleted, this function will increment or decrement the month log on that day.
    @MainActor
    func insertOrRemoveEventFromMonthLog(_ event: RecallCalendarEvent, inserted: Bool) async {
        let firstOfMonth = Date.now.getStartOfMonth()
        
        if event.startTime > firstOfMonth {
            var monthLog = Array(currentMonthLog)
            
            let index = floor(event.startTime.timeIntervalSince(firstOfMonth) / Constants.DayTime)
            monthLog[Int(index)] += inserted ? 1 : -1
            
            updateCurrrentMonthLog(with: monthLog)
            self.writeTodaysEventsToStore()
        }
    }
    
//    MARK: changeEventInMonthLog
    func changeEventInMonthLog() async {
        await self.setCurrentMonthLog()
        await self.writeTodaysEventsToStore()
    }

}
