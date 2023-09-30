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
    
    let events: [RecallCalendarEvent]
    
    @State var showingGoalCreationView: Bool = false
    
    
//    MARK: ViewBuilder
    @ViewBuilder
    static func makeGoalPrioritySection( _ priority: RecallGoal.Priority, goals: [RecallGoal], events: [RecallCalendarEvent] ) -> some View {
    
        let filtered = goals.filter { goal in goal.priority == priority.rawValue }
        
        if filtered.count != 0 {
            VStack(alignment: .leading) {
                UniversalText( priority.rawValue, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                
                LazyVGrid(columns: [ .init(GridItem.Size.adaptive(minimum: 350, maximum: 800),
                                           spacing: 10,
                                           alignment: .center) ]) {
                
                    ForEach( Array(filtered), id: \.label ) { goal in
                        GoalPreviewView(goal: goal, events: events)
                            .padding(.bottom, 5)
                    }
                }
            }.padding(.bottom)
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                UniversalText( "Goals", size: Constants.UITitleTextSize, font: .syneHeavy, true )
                Spacer()
                LargeRoundedButton("Add Goal", icon: "arrow.up") { showingGoalCreationView = true }
            }
            
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading) {
                    if goals.count != 0 {
                        ForEach( RecallGoal.Priority.allCases) { priority in
                            GoalsPageView.makeGoalPrioritySection(priority, goals: Array(goals), events: events)
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
        .sheet(isPresented: $showingGoalCreationView) { GoalCreationView.makeGoalCreationView(editing: false) }
    }
}
