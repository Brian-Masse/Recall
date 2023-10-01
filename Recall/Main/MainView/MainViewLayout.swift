//
//  MainViewLayout.swift
//  Recall
//
//  Created by Brian Masse on 9/29/23.
//

import Foundation
import SwiftUI

//MARK: macOS

#if os(macOS)
struct macOSMainViewNavigation: View {
    
    @Binding var page: MainPage
    @Binding var appPage: ContentView.EntryPage
    @Binding var currentDay: Date
    
    let arrGoals: [RecallGoal]
    let arrEvents: [RecallCalendarEvent]
    
    var body: some View {
    
        NavigationSplitView {

            MacOSSideBar(mainPage: $page)
                .navigationTitle("Recall.")
            
        } detail: {
            
            switch page {
            case .calendar:                 CalendarPageView(events: arrEvents, currentDay: $currentDay, appPage: $appPage)
            case let .goals(priority):      GoalsPageView(priority, events: arrEvents)
                
            case .categories:               CategoriesPageView(events: arrEvents)
            case .data:                     DataPageView(events: arrEvents, page: $page, currentDay: $currentDay)
            }
        }
    }
}

#else
//MARK: iOS
struct iOSMainViewNavigation: View {
    
    @Binding var page: MainPage
    @Binding var appPage: ContentView.EntryPage
    @Binding var currentDay: Date
    
    let arrEvents: [RecallCalendarEvent]
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            TabView(selection: $page) {
            
                CalendarPageView(events: arrEvents, currentDay: $currentDay, appPage: $appPage)      .tag( MainPage.calendar )
                GoalsPageView(events: arrEvents )                           .tag( MainPage.goals )
                CategoriesPageView(events: arrEvents )                      .tag( MainPage.categories )
                DataPageView(events: arrEvents, page: $page, currentDay: $currentDay)         .tag( MainPage.data )

            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            iOSTabBar(pageSelection: $page)
        }
    }
}
#endif
