//
//  RecallWidgetCalendarEvent.swift
//  Recall-WidgetExtension
//
//  Created by Brian Masse on 12/13/24.
//

import Foundation
import WidgetKit

//MARK: WidgetStorageKeys
struct WidgetStorageKeys {
    enum widgets: String {
        case favoriteEventWidgetKind = "com.recall.widget.favoriteEvent"
    }
    
    static let suiteName: String = "Masse-Brian.Recall.Recall-Widget"
    
    static let recentFavoriteEvent = "recentFavoriteEvent"
}

//MARK: - WidgetStorage
class WidgetStorage {
    
    var group: UserDefaults? = nil
    
    static let shared = WidgetStorage()
    
    private func initializeGroup() -> UserDefaults? {
        if group != nil { return group }
        if let group = UserDefaults(suiteName: WidgetStorageKeys.suiteName) {
            self.group = group
            return group
        }
        return nil
    }
    
//    MARK: saveEvent
    func saveEvent(_ event: RecallWidgetCalendarEvent, for key: String) {
        if let group = initializeGroup() {
            if let encodedEvent = try? JSONEncoder().encode(event) {
                group.set(encodedEvent, forKey: key)
            }
        }
    }
    
//    MARK: retrieveEvent
    func retrieveEvent( for key: String ) -> RecallWidgetCalendarEvent? {
        if let group = initializeGroup() {
            if let encodedEvent = group.data(forKey: key) {
                return try? JSONDecoder().decode(RecallWidgetCalendarEvent.self, from: encodedEvent)
            }
        }
        return nil
    }
}


//MARK: - RecallWidgetCalendarEvent
class RecallWidgetCalendarEvent: Codable, TimelineEntry {
    let date: Date
    
    let title: String
    let notes: String
    
    let startTime: Date
    let endTime: Date
    
//    MARK: init
    init( title: String, notes: String, startTime: Date, endTime: Date) {
        self.title = title
        self.notes = notes
        self.startTime = startTime
        self.endTime = endTime
        self.date = .now
    }
}
