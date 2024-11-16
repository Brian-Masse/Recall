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
    case recallCalendarEventView( indexOfEvent: Int, events: [RecallCalendarEvent], namespace: Namespace.ID )

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
    case eventCreationView
    case eventEdittingView( event: RecallCalendarEvent )
    
    case profileView
    case monthlyCalendarView

    var id: Self { return self }
}

//MARK: FullScreenCover
enum RecallFullScreenCover: Identifiable, Hashable {
    
    case recallGoalEventView( goal: RecallGoal )

    var id: Self { return self }
}

extension RecallFullScreenCover {
    // Conform to Hashable
    func hash(into hasher: inout Hasher) { }
}
