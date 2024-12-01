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
    
    private var recallLog: [String: Int] = [:]
    
    @MainActor
    func resetRenderStatus() {
        self.rendered = false
        self.recallLog.removeAll()
    }
    
    @MainActor
    func recallWasCompleted(on date: Date) -> Int { recallLog[ date.getDayKey() ] ?? 0 }
        
//    MARK: renderCalendar
//    for every day in the calendar, check whether the recallWasCompleted
    @MainActor
    func renderCalendar( events: [RecallCalendarEvent] ) async {
        if events.isEmpty { return }
        if self.rendered { return }

        for event in events {
            let key = event.startTime.getDayKey()
            if let val = self.recallLog[ key ] { self.recallLog[ key ] = val + 1
            } else { self.recallLog[ key ] = 1 }
        }
        self.rendered = true
        self.objectWillChange.send()
    }
}
