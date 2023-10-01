//
//  CalendarView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift


//MARK: MainView
struct MainView: View {
    
    
//    MARK: Tba Node Definition
//    These are how the different tab / side bars present the different pages of the app
    static let TabBarNodes: [TabBarNode] = [
        .init("Recall",  icon: "calendar",       page: .calendar),
        .init("Goals",   icon: "flag.checkered", page: .goals()),
        .init("Tags",    icon: "tag",            page: .categories),
        .init("Data",    icon: "chart.bar",      page: .data)
    ]
    
    static let MacOSTabBarNodes: [TabBarNode] = [
        .init("Recall",     icon: "calendar",           page: .calendar),
        
        .init("Goals",      icon: "flag.checkered",     page: .goals()),
        .init("High",       icon: "exclamationmark.3",  page: .goals(.high), indent: true),
        .init("medium",     icon: "exclamationmark.2",  page: .goals(.medium), indent: true),
        .init("low",        icon: "exclamationmark",    page: .goals(.low), indent: true),
        
        .init("tags & templates",       icon: "tag",                page: .categories),
        .init("Tags",       icon: "tag",                page: .calendar, indent: true),
        .init("Templates",  icon: "airport.extreme",    page: .calendar, indent: true),
        
        .init("Data",       icon: "chart.bar",          page: .data),
        .init("overview",   icon: "lines.measurement.horizontal",   page: .calendar, indent: true),
        .init("events",     icon: "calendar.day.timeline.left",     page: .calendar, indent: true),
        .init("goals",      icon: "flag.checkered",                 page: .calendar, indent: true),
        
    ]


//    MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedResults( RecallCalendarEvent.self, where: { event in event.startTime > RecallModel.getEarliestEventDate() } ) var events
    @ObservedResults( RecallGoal.self ) var goals
    
    @State var currentPage: MainPage = .calendar
    @State var shouldRefreshData: Bool = false
    @Binding var appPage: ContentView.EntryPage
    @State var currentDay: Date = .now
    
    private func refreshData(events: [RecallCalendarEvent]? = nil, goals: [RecallGoal]? = nil) async {
        await RecallModel.dataModel.updateProperties(events: events ?? nil, goals: goals ?? nil)
    }
    
    
    //    MARK: Body
    var body: some View {
    
        let arrEvents = Array(events)
        let arrGoals = Array(goals)

        VStack {
#if os(macOS)
            macOSMainViewNavigation(page: $currentPage,
                                    appPage: $appPage,
                                    currentDay: $currentDay, 
                                    arrGoals: arrGoals,
                                    arrEvents: arrEvents)
#else
            
            iOSMainViewNavigation(page: $currentPage,
                                  appPage: $appPage,
                                  currentDay: $currentDay,
                                  arrEvents: arrEvents)
#endif
        }
            .onAppear {
                Task { await refreshData(events: Array(events), goals: Array(goals)) }
                RecallModel.shared.setTint(from: colorScheme)
                Constants.setupConstants()
            }
            .onChange(of: events)   { newValue in Task { await refreshData(events: Array(newValue), goals: Array(goals)) } }
            
            .onChange(of: colorScheme) { newValue in
                RecallModel.shared.setTint(from: newValue)
            }
            .ignoresSafeArea()
            .universalBackground()
    }
}
