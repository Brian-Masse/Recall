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
        case monthlyLog = "com.recall.widget.monthlyLog"
        case todaysEvents = "com.recall.widget.todaysEvents"
    }
    
    static let suiteName: String = "group.Masse-Brian.Recall"
    
//    favorite events widgets
    static let recentFavoriteEvent = "recentFavoriteEvent"
    static let favoriteEvents = "favoriteEvents"
    
//    monthly view widgets
    static let currentMonthLog = "currentMonthLog"
    
//    todays events widgets
    static let todaysEvents = "todaysEvents"
    
//    accentColor
    static let updateAccentColorTrigger = "updateAccentColorTrigger"
    static let ligthAccent = "lightAccent"
    static let darkAccent = "darkAccent"
    static let mixValue = "mixValue"
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
    
//    MARK: saveEvents
    func saveEvents(_ events: [RecallWidgetCalendarEvent], for key: String, timelineKind: WidgetStorageKeys.widgets) {
        if let group = initializeGroup() {
            
            if let encodedEvents = try? JSONEncoder().encode(events) {
                group.set(encodedEvents, forKey: key)
            }
            
            WidgetCenter.shared.reloadTimelines(ofKind: timelineKind.rawValue)
        }
    }
    
//    MARK: retrieveEvents
    func retrieveEvents( for key: String ) -> [RecallWidgetCalendarEvent]? {
        if let group = initializeGroup() {
            if let encodedEvents = group.data(forKey: key) {
                
                return try? JSONDecoder().decode([RecallWidgetCalendarEvent].self, from: encodedEvents)
            }
        }
        
        return nil
    }
    
//    MARK: saveList
    func saveList( _ list: [Int], for key: String, timelineKind: WidgetStorageKeys.widgets ) {
        if let group = initializeGroup() {
            if let encodedList = try? JSONEncoder().encode(list) {
                group.set(encodedList, forKey: key)
            }
            
            WidgetCenter.shared.reloadTimelines(ofKind: timelineKind.rawValue)
        }
    }
    
//    MARK: retrieveList
    func retrieveList(for key: String) -> [Int] {
        if let group = initializeGroup() {
            if let encodedList = group.data(forKey: key) {
                let list = try? JSONDecoder().decode([Int].self, from: encodedList)
                return list ?? []
            }
        }
        return []
    }
    
//    MARK: saveColor
    func saveColor(_ color: Color, for key: String) {
        if let group = initializeGroup() {
            let components = color.components
            let compList = [components.red, components.green, components.blue]
            
            if let list = try? JSONEncoder().encode(compList) {
                group.set(list, forKey: key)
            }
        }
    }
    
//    MARK: retrieveColor
    func retrieveColor(for key: String) -> Color {
        if let group = initializeGroup() {
            if let encodedList = group.data(forKey: key) {
                if let list = try? JSONDecoder().decode([Double].self, from: encodedList) {
                    return Color(red: list[0], green: list[1], blue: list[2])
                }
            }
        }
        return .blue
    }
    
//    MARK: saveBasicValue
    func saveBasicValue<T: Codable>(value: T, key: String) {
        if let group = initializeGroup() {
            if let encodedValue = try? JSONEncoder().encode(value) {
                group.set(encodedValue, forKey: key)
            }
        }
    }
    
//    MARK: retrieveBasicValue
    func retrieveBasicValue<T: Codable>(key: String) -> T? {
        if let group = initializeGroup() {
            if let encodedValue = group.data(forKey: key) {
                return try? JSONDecoder().decode(T.self, from: encodedValue)
            }
        }
        return nil
    }
    
    //MARK: - UpdateAccentColor
    func checkForUpdateAccentColor() {
        if let updateTrigger: Bool = WidgetStorage.shared.retrieveBasicValue(key: WidgetStorageKeys.updateAccentColorTrigger) {
            
            if updateTrigger {
                let lightAccentColor = WidgetStorage.shared.retrieveColor(for: WidgetStorageKeys.ligthAccent)
                let darkAccentColor = WidgetStorage.shared.retrieveColor(for: WidgetStorageKeys.darkAccent)
                let mixValue: Double = WidgetStorage.shared.retrieveBasicValue(key: WidgetStorageKeys.mixValue) ?? 0
                
                updateAccentColor(lightAccent: lightAccentColor, darkAccent: darkAccentColor, mixValue: mixValue)
                
                WidgetStorage.shared.saveBasicValue(value: false, key: WidgetStorageKeys.updateAccentColorTrigger)
            }
        }
    }

    //This function takes in a new accentColor / colors, and sets it in the Colors variable
    private func updateAccentColor(lightAccent: Color, darkAccent: Color, mixValue: Double) {
        Colors.setColors(secondaryLight: Colors.defaultSecondaryLight.safeMix(with: lightAccent, by: mixValue),
                         secondaryDark: Colors.defaultSecondaryDark.safeMix(with: darkAccent, by: mixValue),
                         lightAccent: lightAccent,
                         darkAccent: darkAccent)
    }
}

//MARK: - RecallWidgetCalendarEvent
class RecallWidgetCalendarEvent: Codable, TimelineEntry {
    static let blank: String = "BLANK-EVENT"
    static let placeholder: String = "PLACEHOLDER"
    
    let date: Date
    let id: String
    
    let title: String
    let notes: String
    let tag: String
    
    private let r: Double
    private let g: Double
    private let b: Double
    
    let startTime: Date
    let endTime: Date
    
//    MARK: init
    init( id: String = "",
          title: String = RecallWidgetCalendarEvent.placeholder,
          notes: String = "placeholder",
          tag: String = "?",
          startTime: Date = .now,
          endTime: Date = .now,
          color: Color = Colors.getAccent(from: .light)) {
        self.id = id
        
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
