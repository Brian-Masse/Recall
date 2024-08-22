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
    
    var filteredEvents: [String:[RecallCalendarEvent]] = [:]
    @Published private(set) var currentDay: Date = Date.now
//    this will be toggled whenever the view should scroll to the currentDay
    @Published private(set) var shouldScrollCalendar: Bool = false
    
    
    @Published var scale: Double = 100
    @Published var gestureInProgress: Bool = false
    
    func setCurrentDay(to day: Date, scrollToDay: Bool = true) {
    
        withAnimation { self.currentDay = day }
        
        if scrollToDay { shouldScrollCalendar.toggle() }
    }
    
//    MARK: Event Filtering
    static func dateKey(from date: Date) -> String { date.formatted(date: .complete, time: .omitted) }
    
    func loadEvents( for day: Date, in events: [RecallCalendarEvent] ) async {
        let key = RecallCalendarViewModel.dateKey(from: day)
        if filteredEvents[key] != nil { return }
        
        let filteredEvents = events.filter { event in
            event.startTime.matches(day, to: .day) &&
            event.startTime.matches(day, to: .month) &&
            event.startTime.matches(day, to: .year)
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
        }
    }
    
}
