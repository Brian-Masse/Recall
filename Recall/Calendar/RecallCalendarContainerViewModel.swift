//
//  RecallCalendarContainerViewModel.swift
//  Recall
//
//  Created by Brian Masse on 8/21/24.
//

import Foundation
import SwiftUI
import UIUniversals

// handles the events, currentDay, and selections of the calendarContainer
class RecallCalendarContainerViewModel: ObservableObject {
    
    static let shared = RecallCalendarContainerViewModel()
    
    //    MARK: Vars
    var filteredEvents: [String:[RecallCalendarEvent]] = [:]
    
    @Published private(set) var currentDay: Date = Date.now
    //    this will be toggled whenever the view should scroll to the currentDay
    @Published private(set) var shouldScrollCalendar: Bool = false
    @Published private(set) var scrollingCalendar: Bool = false
    
//    if the calendar is split into two days, then this indicates which of the day the user is interacting with
    @Published private(set) var subDayIndex: Int = 0
    @Published private(set) var daysPerView: Int = 2
    
    var initialDaysPerView: Int = 2
    
    @Published var scale: Double = 100
    @Published var gestureInProgress: Bool = false
    
    @Published var selecting: Bool = false
    @Published var selection: [ RecallCalendarEvent ] = []
    
    init() {
        self.getScale(from: RecallModel.index.calendarDensity)
        self.daysPerView = RecallModel.index.calendarColoumnCount
        self.initialDaysPerView = daysPerView
    }
    
//    MARK: Setters
    func setCurrentDay(to day: Date, scrollToDay: Bool = true) {
    
        withAnimation { self.currentDay = day }
        
        if scrollToDay {
            shouldScrollCalendar.toggle()
            scrollingCalendar = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.scrollingCalendar = false
            }
        }
    }
    
    func setDaysPerView(to count: Int) { withAnimation {
        self.daysPerView = count
        self.subDayIndex = 0
    }}
    
    func setSubDayIndex(to index: Int) {
        self.subDayIndex = index
    }
    
//    func setWidth( _ width: Double = Date )
    
    func setScale(to scale: Double) {
        let scale = min( 200, max( 40, scale ) )
        self.scale = scale
    }
    
    func getScale(from density: Int) {
        switch density {
        case 0: self.scale = 120
        case 1: self.scale = 85
        case 2: self.scale = 50
        default: break
        }
    }
    
    func getDensity() -> Int {
        switch self.scale {
        case 120: return 0
        case 85 : return 1
        case 50 : return 2
        default: return 0
        }
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
    
    func stopSelecting() { withAnimation {
        self.selection = []
        self.selecting = false
    } }
    
//    MARK: Event Filtering
    func loadEvents( for day: Date, in events: [RecallCalendarEvent] ) async {
//        if abs(currentDay.timeIntervalSince(day) / Constants.DayTime) > 4 { return }
        
        let key = day.getDayKey()
        if filteredEvents[key] != nil { return }
        
        let filteredEvents = events.filter { event in
            let startKey = event.startTime.getDayKey()
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
        let key = day.getDayKey()
        
        if let events = filteredEvents[key] {
            return events
        }
        
        return []
    }
    
    func getEvents(on day: Date, in events: [RecallCalendarEvent]) async -> [RecallCalendarEvent] {
        let key = day.getDayKey()
        
        if let events = filteredEvents[key] { return events }
        
        await loadEvents(for: day, in: events)
        return getEvents(on: day)
    }
    
    
//    called when the events refresh remotely from the server
    func invalidateEvents(newEvents: [RecallCalendarEvent]) {
        self.filteredEvents = [:]
        Task {
//            render the day to the left
            await loadEvents(for: currentDay + Constants.DayTime, in: newEvents )
            
            for i in 0..<daysPerView {
                await loadEvents(for: currentDay - (Constants.DayTime * Double(i)), in: newEvents )
            }
        }
    }
    
}
