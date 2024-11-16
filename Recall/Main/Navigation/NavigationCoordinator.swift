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
class ReccallNavigationCoordinator: RecallNavigationCoordinatorProtocol {
    
    @Published var path: NavigationPath = NavigationPath()
    @Published var tab: RecallNavigationTab = .calendar
    @Published var sheet: RecallNavigationSheet?
    @Published var fullScreenCover: RecallFullScreenCover?
    
    static var shared: ReccallNavigationCoordinator = ReccallNavigationCoordinator()
    
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
        @ObservedObject private var coordinator = ReccallNavigationCoordinator.shared
        
        var body: some View {
            TabView(selection: $coordinator.tab) {
                ForEach( RecallNavigationTab.allCases ) { tab in
                    coordinator.build(tab)
                }
            }
        }
    }
    
    @ViewBuilder
    func build(_ screen: RecallNavigationScreen) -> some View {
        switch screen {
        case .home:
            MainTabView()
            
        case .recallCalendarEventView(event: let event):
            TestCalendarEventView(event: event, events: [])
        }
    }
    
//    MARK: Tab Provider 
    @ViewBuilder
    private func build(_ tab: RecallNavigationTab ) -> some View {
        switch tab {
        case .calendar:
            CalendarPageView(events: [], goals: [], dailySummaries: [])
            
        case .goals:
            GoalsPageView(goals: [], events: [], tags: [])
            
        case .tags:
            CategoriesPageView(events: [], categories: [])
            
        case .data:
            DataPageView(events: [], goals: [], tags: [], mainViewPage: .constant(.calendar), currentDay: .constant(.now))
        }
    }
    
//    MARK: Sheet Provider
    @MainActor
    @ViewBuilder
    func build(_ sheet: RecallNavigationSheet) -> some View {
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
    func build(_ fullScreenCover: RecallFullScreenCover) -> some View {
        switch fullScreenCover {
        case .recallGoalEventView(let goal):
            GoalView(goal: goal, events: [])
        }
    }
}
