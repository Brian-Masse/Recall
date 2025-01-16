//
//  NavgiationStyle.swift
//  Recall
//
//  Created by Brian Masse on 11/15/24.
//

import Foundation
import SwiftUI

//MARK: Screen
enum RecallNavigationScreen: Identifiable, Hashable {
    case home
    
    case onBoarding
    case recallEventView( id: String, event: RecallCalendarEvent, events: [RecallCalendarEvent], Namespace: Namespace.ID )
    case recallEventCarousel( id: Int, events: [RecallCalendarEvent], namespace: Namespace.ID )
    case recallGoalEventView( goal: RecallGoal, id: String, Namespace: Namespace.ID )
    
    case profileView(namespace: Namespace.ID)
    case monthlyCalendarView(namespace: Namespace.ID)

    var id: Self { return self }
}

//MARK: Tab
enum RecallNavigationTab: Identifiable, Hashable, CaseIterable {
    case calendar
    case goals
    case tags
    case data
    
    var id: Self { return self }
}

//MARK: Sheet
enum RecallNavigationSheet: Identifiable, Hashable {
    case eventCreationView( favorite: Bool = false )
    case eventEdittingView( event: RecallCalendarEvent )
    
    case goalCreationView( editting: Bool, goal: RecallGoal? = nil )
    case tagCreationView( editting: Bool, tag: RecallCategory? = nil)
    case indexEditingView( index: RecallIndex )

    var id: Self { return self }
}

//MARK: HalfScreenSheet
enum RecallNavigationHalfScreenSheet: Identifiable, Hashable {
    case selectionView

    var id: Self { return self }
}

//MARK: FullScreenCover
enum RecallFullScreenCover: Identifiable, Hashable {

    case none
    
    var id: Self { return self }
}

extension RecallFullScreenCover {
    // Conform to Hashable
    func hash(into hasher: inout Hasher) { }
}
