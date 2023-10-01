//
//  GoalsPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct GoalsPageView: View {
    
//    MARK: Vars
    
    @ObservedResults( RecallGoal.self ) var goals
    @ObservedResults( RecallCategory.self ) var categories
    
    let priority: RecallGoal.Priority
    let events: [RecallCalendarEvent]
    
    @State var showingGoalCreationView: Bool = false
    
    init( _ priority: RecallGoal.Priority, events: [RecallCalendarEvent] ) {
        self.priority   = priority
        self.events     = events
        
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private static func makeGoalPrioritySection( _ priority: RecallGoal.Priority, goals: [RecallGoal], events: [RecallCalendarEvent], title: Bool = true ) -> some View {
    
        let filtered = goals.filter { goal in goal.priority == priority.rawValue }
        
        if filtered.count != 0 {
            VStack(alignment: .leading) {
                if title {
                    UniversalText( priority.rawValue, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                }
                
                LazyVGrid(columns: [ .init(GridItem.Size.adaptive(minimum: 350, maximum: 800),
                                           spacing: 10,
                                           alignment: .center) ]) {
                
                    ForEach( Array(filtered), id: \.label ) { goal in
                        GoalPreviewView(goal: goal, events: events)
                            .padding(.bottom, 5)
                    }
                }
            }
            .padding(.bottom)
        }
    }
    
//    MARK: Naming Functions
    private func getPageName() -> String {
        switch priority {
        case .all:  return "Goals"
        default:    return "\(priority.rawValue.firstUppercased ) Priority Goals"
        }
    }
    
    private func getButtonName() -> String {
        switch priority {
        case .all:  return "Add Goal"
        default:    return "Add \(priority.rawValue.firstUppercased ) Priority Goal"
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                UniversalText(getPageName(), size: Constants.UITitleTextSize, font: .syneHeavy, true )
                Spacer()
                LargeRoundedButton(getButtonName(), icon: "arrow.up") { showingGoalCreationView = true }
            }
            
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading) {
                    if goals.count != 0 {
                        if priority == .all {
                            ForEach( RecallGoal.Priority.allCases) { priority in
                                GoalsPageView.makeGoalPrioritySection(priority,
                                                                      goals: Array(goals),
                                                                      events: events)
                            }
                        } else {
                            GoalsPageView.makeGoalPrioritySection(priority,
                                                                  goals: Array(goals),
                                                                  events: events,
                                                                  title: false)
                        }
                    } else {
                        UniversalText( Constants.goalsSplashPurpose,
                                       size: Constants.UIDefaultTextSize,
                                       font: Constants.mainFont)
                    }
                }
            .padding(.bottom, Constants.UIBottomOfPagePadding)
            }
        }
        .padding(7)
        .universalBackground()
        .sheet(isPresented: $showingGoalCreationView) { GoalCreationView.makeGoalCreationView(editing: false,
                                                                                              startingPriority: priority == .all ? .medium : priority) }
    }
}
