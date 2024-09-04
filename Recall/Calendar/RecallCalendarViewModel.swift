//
//  RecallCalendarViewModel.swift
//  Recall
//
//  Created by Brian Masse on 8/21/24.
//

import Foundation
import SwiftUI
import UIUniversals

class RecallCalendarViewModel: ObservableObject {
    
    static let shared = RecallCalendarViewModel()
    
//    MARK: Vars
    var filteredEvents: [String:[RecallCalendarEvent]] = [:]
    
    @Published private(set) var currentDay: Date = Date.now
//    this will be toggled whenever the view should scroll to the currentDay
    @Published private(set) var shouldScrollCalendar: Bool = false
    
    @Published var scale: Double = 100
    @Published var gestureInProgress: Bool = false
    
    @Published var selecting: Bool = false
    @Published var selection: [ RecallCalendarEvent ] = []
    
//    MARK: Setters
    func setCurrentDay(to day: Date, scrollToDay: Bool = true) {
    
        withAnimation { self.currentDay = day }
        
        if scrollToDay { shouldScrollCalendar.toggle() }
    }
    
    func setScale(to scale: Double) {
        let scale = min( 200, max( 40, scale ) )
        self.scale = scale
    }
    
//    MARK: Positioning Functions
//    this translates a position into a date
//    it is involved in placing events on the timeline correctly
    func getTime(from position: CGFloat, on date: Date) -> Date {
        let timeInterval = position * scale
        let hour = (timeInterval / Constants.HourTime).rounded(.down)
        let minutes = ((timeInterval / Constants.HourTime) - hour) * CGFloat(Constants.MinuteTime)
        
        var comps = DateComponents()
        comps.hour = Int(hour)
        comps.minute = Int(minutes)
        
        return Calendar.current.date(byAdding: comps, to: date.resetToStartOfDay()) ?? .now
    }
    
    func roundPosition(_ position: Double, to timeRounding: TimeRounding) -> Double {
        let hoursInPosition = (position * scale) / Constants.HourTime
        let roundedHours = (hoursInPosition * Double(timeRounding.rawValue)).rounded(.down) / Double(timeRounding.rawValue)
        return (roundedHours * Constants.HourTime) / scale
    }
    
//    MARK: Selecting
    func selectEvent(_ event: RecallCalendarEvent) { withAnimation {
        if let index = selection.firstIndex(where: {$0 == event} ) {
            selection.remove(at: index)
        } else {
            selection.append( event )
        }
    }}
    
//    MARK: Event Filtering
    static func dateKey(from date: Date) -> String { date.formatted(date: .complete, time: .omitted) }
    
    func loadEvents( for day: Date, in events: [RecallCalendarEvent] ) async {
        let key = RecallCalendarViewModel.dateKey(from: day)
        if filteredEvents[key] != nil { return }
        
        let filteredEvents = events.filter { event in
            let startKey = RecallCalendarViewModel.dateKey(from: event.startTime)
            return key == startKey
        }.sorted { event1, event2 in
            event1.startTime < event2.startTime
        }

        DispatchQueue.main.sync {
            withAnimation {
                self.filteredEvents[key] = filteredEvents
                self.objectWillChange.send()
            }
        }
    }
    
    func getEvents(on day: Date) -> [RecallCalendarEvent] {
        let key = RecallCalendarViewModel.dateKey(from: day)
        
        if let events = filteredEvents[key] {
            return events
        }
        return []
    }
    
    
//    called when the events refresh remotely from the server
    func invalidateEvents(newEvents: [RecallCalendarEvent]) {
        self.filteredEvents = [:]
        
        Task {
            await loadEvents(for: currentDay, in: newEvents )
            await loadEvents(for: currentDay - Constants.DayTime, in: newEvents )
        }
    }
    
}
