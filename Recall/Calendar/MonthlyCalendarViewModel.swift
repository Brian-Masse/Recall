//
//  MonthlyCalendarViewModel.swift
//  Recall
//
//  Created by Brian Masse on 11/16/24.
//

import Foundation
import SwiftUI

//MARK: CalendarPageViewModel
class CalendarPageViewModel: ObservableObject {
    
    static let shared: CalendarPageViewModel = CalendarPageViewModel()
    
//    MARK: Vars
    private var rendered: Bool = false
    
    private var recallLog: [String: Bool] = [:]
    private var renderedMonths: [String: Bool] = [:]
    
    
    private func getStartOfMonth(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: date)))!
    }
    
    @MainActor
    func recallWasCompleted(on date: Date) -> Bool { recallLog[ date.getDayKey() ] ?? false }
    
    @MainActor
    func recallWasCompleted(key: String) -> Bool { recallLog[ key ] ?? false }
        
//    MARK: renderCalendar
//    for every day in the calendar, check whether the recallWasCompleted
    @MainActor
    func renderCalendar( events: [RecallCalendarEvent] ) {
        if events.isEmpty { return }
        if self.rendered { return }
        
        var currentKey = events[0].startTime.getDayKey()
        for event in events {
            
            let key = event.startTime.getDayKey()
            if key != currentKey {
                self.recallLog[ currentKey ] = true
                currentKey = key
            }
        }
        self.rendered = true
        self.objectWillChange.send()
    }
    
//    MARK: RenderMonth
//    goes through the days of a month and determines if each day was rendered or not
    func renderMonth(_ month: Date, events: [RecallCalendarEvent]) async {
        if self.renderedMonths[ month.getMonthKey() ] ?? false { return }
        
        let startOfMonth = getStartOfMonth(for: month)
        let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let events = events.filter { event in
            event.startTime > startOfMonth && event.startTime < endOfMonth
        }
        
        var currentDay = -1
        
        for event in events {
            let dayNum = Calendar.current.component(.day, from: event.startTime)
            
            if dayNum > 0 {
                self.recallLog[event.startTime.getDayKey()] = true
                currentDay += 1
            }
        }
        self.renderedMonths[ month.getMonthKey() ] = true
    }
}
