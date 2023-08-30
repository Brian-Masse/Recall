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
    
    @ObservedResults( RecallGoal.self ) var goals
    @ObservedResults( RecallCategory.self ) var categories
    
    let events: [RecallCalendarEvent]
    
    @State var showingGoalCreationView: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                UniversalText( "Goals", size: Constants.UITitleTextSize, font: .syneHeavy, true )
                Spacer()
                LargeRoundedButton("Add Goal", icon: "arrow.up") { showingGoalCreationView = true }
            }
            
            ScrollView(.vertical) {
//                LazyVStack {
                VStack(alignment: .leading) {
                    if goals.count != 0 {
                        
                        ForEach( RecallGoal.Priority.allCases) { priority in
                        
                            let filtered = goals.filter { goal in goal.priority == priority.rawValue }
                            
                            if filtered.count != 0 {
                                VStack(alignment: .leading) {
                                    UniversalText( priority.rawValue, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                                    
                                    ForEach( Array(filtered), id: \.label ) { goal in
                                        GoalPreviewView(goal: goal, events: events)
                                            .padding(.bottom, 5)
                                    }
                                }.padding(.bottom)
                            }
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
