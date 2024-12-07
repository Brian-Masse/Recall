//
//  RecallWidgetCalendarEvent.swift
//  Recall-WidgetExtension
//
//  Created by Brian Masse on 12/13/24.
//

import Foundation
import WidgetKit
import SwiftUI
import UIUniversals

//MARK: - WidgetStorageKeys
struct WidgetStorageKeys {
    enum widgets: String {
        case mostRecentFavoriteEvent = "com.recall.widget.favoriteEvent"
    }
    
    static let suiteName: String = "group.Masse-Brian.Recall"
    
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
    func saveEvent(_ event: RecallWidgetCalendarEvent, for key: String, timelineKind: WidgetStorageKeys.widgets) {
        if let group = initializeGroup() {
            
            if let encodedEvent = try? JSONEncoder().encode(event) {
                group.set(encodedEvent, forKey: key)
            }
            
            WidgetCenter.shared.reloadTimelines(ofKind: timelineKind.rawValue)
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
    let tag: String
    
    private let r: Double
    private let g: Double
    private let b: Double
    
    let startTime: Date
    let endTime: Date
    
//    MARK: init
    init( title: String, notes: String = "", tag: String = "?", startTime: Date = .now, endTime: Date = .now, color: Color = Colors.getAccent(from: .light)) {
        self.title = title
        self.notes = notes
        self.tag = tag
        self.startTime = startTime
        self.endTime = endTime
        self.date = .now
        
        let components = color.components
        self.r = components.red
        self.g = components.green
        self.b = components.blue
    }
    
    var color: Color {
        .init(r * 255, g * 255, b * 255)
    }
}
