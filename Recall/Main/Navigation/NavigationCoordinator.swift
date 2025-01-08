//
//  NavigationCoordinator.swift
//  Recall
//
//  Created by Brian Masse on 11/15/24.
//

import Foundation
import SwiftUI

//MARK: matchNavigationEffectExtension
private struct NavigationZoomTransitionViewModifer<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

private struct NavigationZoomMatchViewModifier<ID: Hashable>: ViewModifier {
    
    let id: ID
    let namespace: Namespace.ID
    
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

extension View {
    func safeZoomTransition<ID: Hashable>(id: ID, namespace: Namespace.ID) -> some View {
        modifier(NavigationZoomTransitionViewModifer(id: id, namespace: namespace))
    }
    
    func safeZoomMatch<ID: Hashable>(id: ID, namespace: Namespace.ID) -> some View {
        modifier(NavigationZoomMatchViewModifier(id: id, namespace: namespace))
    }
}

//MARK: RecallNavigationMatchKeys
struct RecallnavigationMatchKeys {
    static let profileView = "profileView"
    static let monthlyCalendarView = "monthlyCalendarView"
}

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
    @Published var sheet2: RecallNavigationSheet?
    
    @Published var halfScreenSheet: RecallNavigationHalfScreenSheet?
    @Published var halfScreenSheetDismiss: (() -> Void)?
    
    @Published var fullScreenCover: RecallFullScreenCover?
    
    static var shared: RecallNavigationCoordinator = RecallNavigationCoordinator()
    
//    MARK: - Navigation methods
    func dismiss() {
        self.sheet = nil
        self.sheet2 = nil
        self.halfScreenSheet = nil
        self.fullScreenCover = nil
        path.removeLast()
    }
    
    func goTo(_ tab: RecallNavigationTab ) { self.tab = tab }
    
    func push(_ screen: RecallNavigationScreen) { withAnimation { path.append(screen) }}
    
    func presentSheet(_ sheet: RecallNavigationSheet) {
        if self.sheet == nil { self.sheet = sheet }
        else { self.sheet2 = sheet }
    }
    
    func presentSheet(_ sheet: RecallNavigationHalfScreenSheet, onDismiss: (() -> Void)? = nil) {
        self.halfScreenSheet = sheet
        self.halfScreenSheetDismiss = onDismiss
    }
    
    func presentFullScreenCover(_ fullScreenCover: RecallFullScreenCover) { self.fullScreenCover = fullScreenCover }
    
    func pop() { withAnimation { path.removeLast() } }
    
    func popToRoot() { path.removeLast(path.count) }
    
    func dismissSheet() { self.sheet = nil }
    
    func dismissFullScreenOver() { self.fullScreenCover = nil }
    
//    MARK: - Screen Provider
    private struct MainTabView: View {
        @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
        
        let data: MainView.RecallData
        
        var body: some View {
            ZStack(alignment: .bottom) {
                TabView(selection: $coordinator.tab) {
                    ForEach( RecallNavigationTab.allCases ) { tab in
                        coordinator.build(tab, data: data)
                    }
                }
                
                TabBar()
                    .padding(.bottom, 35)
                    .ignoresSafeArea(.keyboard)
            }
        }
    }
    
    @MainActor
    @ViewBuilder
    func build(_ screen: RecallNavigationScreen, data: MainView.RecallData) -> some View {
        switch screen {
        case .home:
            MainTabView(data: data)
        
        case .recallEventView(id: let id, event: let event, events: let events, Namespace: let namespace):
            RecallCalendarEventView(event: event, events: events)
                .safeZoomTransition(id: id, namespace: namespace)
            
        case .recallEventCarousel(id: let id, events: let events, namespace: let namespace):
            CalendarEventCarousel(events: events, startIndex: id)
                .safeZoomTransition(id: id, namespace: namespace)
            
        case .recallGoalEventView(let goal, let id, let namespace):
            GoalView(goal: goal, events: data.events)
                .safeZoomTransition(id: id, namespace: namespace)
            
        case .profileView(namespace: let namespace):
            ProfileView()
                .safeZoomTransition(id: RecallnavigationMatchKeys.profileView, namespace: namespace)
            
        case .monthlyCalendarView(namespace: let namespace):
            MonthlyCalendarView()
                .safeZoomTransition(id: RecallnavigationMatchKeys.monthlyCalendarView, namespace: namespace)
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
            GoalsPageView(goals: data.goals)
            
        case .tags:
            CategoriesPageView(events: data.events,
                               categories: data.tags)
            
        case .data:
            DataPageView(events: data.events,
                         goals: data.goals,
                         tags: data.tags,
                         currentDay: .constant(.now))
        }
    }
    
//    MARK: Sheet Provider
    @MainActor
    @ViewBuilder
    func build(_ sheet: RecallNavigationSheet, data: MainView.RecallData) -> some View {
        switch sheet {
        case .eventCreationView(let favorite):
            CalendarEventCreationView.makeEventCreationView(favorite: favorite)
            
        case .eventEdittingView(let event):
            CalendarEventCreationView.makeEventCreationView(editing: true, event: event)
            
        case .goalCreationView(let editing, let goal):
            if editing { GoalCreationView.makeGoalCreationView(editing: true, goal: goal) }
            else { GoalCreationView.makeGoalCreationView(editing: false) }
            
        case .tagCreationView(let editing, let tag):
            if editing { CategoryCreationView.makeCateogryCreationView(editing: true, tag: tag) }
            else { CategoryCreationView.makeCateogryCreationView(editing: false) }
            
        case .indexEditingView(let index):
            ProfileEditorView.makeProfileEditorView(from: index)
            
        }
    }
    
    @ViewBuilder
    func build(_ sheet: RecallNavigationHalfScreenSheet, data: MainView.RecallData) -> some View {
        switch sheet {
        case .selectionView:
            EventSelectionEditorView()
        }
    }
    
//    MARK: fullScreenCover Provider
    @ViewBuilder
    func build(_ fullScreenCover: RecallFullScreenCover, data: MainView.RecallData) -> some View {
        EmptyView()
    }
}
