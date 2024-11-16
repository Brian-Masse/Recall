//
//  NavigationCoordinator.swift
//  Recall
//
//  Created by Brian Masse on 11/15/24.
//

import Foundation
import SwiftUI



//MARK: RecallNavigationCoordinatorProtocol
protocol RecallNavigationCoordinatorProtocol: ObservableObject {
    var path: NavigationPath { get set }
    var sheet: RecallNavigationSheet? { get set }
    var fullScreenCover: RecallFullScreenCover? { get set }

    func push(_ screen:  RecallNavigationScreen)
    func presentSheet(_ sheet: RecallNavigationSheet)
    func presentFullScreenCover(_ fullScreenCover: RecallFullScreenCover)
    func pop()
    func popToRoot()
    func dismissSheet()
    func dismissFullScreenOver()
}


// MARK: AppCoordinator
class RecallNavigationCoordinator: RecallNavigationCoordinatorProtocol {
    
    @Published var path: NavigationPath = NavigationPath()
    @Published var tab: RecallNavigationTab = .calendar
    @Published var sheet: RecallNavigationSheet?
    @Published var fullScreenCover: RecallFullScreenCover?
    
    static var shared: RecallNavigationCoordinator = RecallNavigationCoordinator()
    
//    MARK: - Navigation methods
    func goTo(_ tab: RecallNavigationTab ) { self.tab = tab }
    
    func push(_ screen: RecallNavigationScreen) { path.append(screen) }
    
    func presentSheet(_ sheet: RecallNavigationSheet) { self.sheet = sheet }
    
    func presentFullScreenCover(_ fullScreenCover: RecallFullScreenCover) { self.fullScreenCover = fullScreenCover }
    
    func pop() { path.removeLast() }
    
    func popToRoot() { path.removeLast(path.count) }
    
    func dismissSheet() { self.sheet = nil }
    
    func dismissFullScreenOver() { self.fullScreenCover = nil }
    
//    MARK: - Screen Provider
    private struct MainTabView: View {
        @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
        
        let data: MainView.RecallData
        
        var body: some View {
            TabView(selection: $coordinator.tab) {
                ForEach( RecallNavigationTab.allCases ) { tab in
                    coordinator.build(tab, data: data)
                }
            }
        }
    }
    
    @ViewBuilder
    func build(_ screen: RecallNavigationScreen, data: MainView.RecallData) -> some View {
        switch screen {
        case .home:
            MainTabView(data: data)
            
        case .recallCalendarEventView(indexOfEvent: let index, events: let events, namespace: let namespace):
            CalendarEventCarousel(events: events, startIndex: index)
                .navigationTransition(.zoom(sourceID: index, in: namespace))
        }
    }
    
//    MARK: Tab Provider 
    @ViewBuilder
    private func build(_ tab: RecallNavigationTab, data: MainView.RecallData ) -> some View {
        switch tab {
        case .calendar:
            CalendarPageView(events: data.events,
                             goals: data.goals,
                             dailySummaries: data.summaries)
            
        case .goals:
            GoalsPageView(goals: data.goals,
                          events: data.events,
                          tags: data.tags)
            
        case .tags:
            CategoriesPageView(events: data.events,
                               categories: data.tags)
            
        case .data:
            DataPageView(events: data.events,
                         goals: data.goals,
                         tags: data.tags,
                         mainViewPage: .constant(.calendar),
                         currentDay: .constant(.now))
        }
    }
    
//    MARK: Sheet Provider
    @MainActor
    @ViewBuilder
    func build(_ sheet: RecallNavigationSheet, data: MainView.RecallData) -> some View {
        switch sheet {
        case .eventCreationView:
            CalendarEventCreationView.makeEventCreationView(currentDay: .now)
            
        case .eventEdittingView(let event):
            CalendarEventCreationView.makeEventCreationView(currentDay: .now, editing: true, event: event)
            
        case .profileView:
            ProfileView()
            
        case .monthlyCalendarView:
            CalendarPage()
        }
    }
    
//    MARK: fullScreenCover Provider
    @ViewBuilder
    func build(_ fullScreenCover: RecallFullScreenCover, data: MainView.RecallData) -> some View {
        switch fullScreenCover {
        case .recallGoalEventView(let goal):
            GoalView(goal: goal, events: [])
        }
    }
}
