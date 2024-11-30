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
    func resetRenderStatus() { self.rendered = false }
    
    @MainActor
    func recallWasCompleted(on date: Date) -> Int { recallLog[ date.getDayKey() ] ?? 0 }
        
//    MARK: renderCalendar
//    for every day in the calendar, check whether the recallWasCompleted
    @MainActor
    func renderCalendar( events: [RecallCalendarEvent] ) async {
        if events.isEmpty { return }
        if self.rendered { return }
        
//        var currentKey = events[0].startTime.getDayKey()
        for event in events {
            let key = event.startTime.getDayKey()
//            if key != currentKey {
            if let val = self.recallLog[ key ] {
                self.recallLog[ key ] = val + 1
            } else {
                self.recallLog[ key ] = 0
            }
                
//                currentKey = key
//            }
        }
        self.rendered = true
        self.objectWillChange.send()
    }
}
