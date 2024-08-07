//
//  GoalsPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

struct GoalsPageView: View {
    
//    MARK: Vars
    let goals: [RecallGoal]
    let events: [RecallCalendarEvent]
    let tags: [RecallCategory]
    
    @State var showingGoalCreationView: Bool = false
    
    @State var scrollPositionBinding: CGPoint = .zero
    
    @ViewBuilder
    private func makeGoalsSection(priority: RecallGoal.Priority) -> some View {
        let filtered = goals.filter { goal in goal.priority == priority.rawValue }

        if filtered.count != 0 {
            VStack(alignment: .leading) {
                UniversalText( priority.rawValue + " priority",
                               size: Constants.UISubHeaderTextSize,
                               font: Constants.titleFont )

                ForEach( Array(filtered), id: \.label ) { goal in
                    GoalPreviewView(goal: goal, events: events)
                        .padding(.bottom, 5)
                }
            }.padding(.bottom)
        }
    }
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                UniversalText( "Goals", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                Spacer()
                
                IconButton("plus", label: "Add Goal") { showingGoalCreationView = true }
            }
            
            TabView {
                if goals.count != 0 {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading) {
                            ForEach( RecallGoal.Priority.allCases) { priority in
                                makeGoalsSection(priority: priority)
                            }
                        }
                        .padding(.bottom, Constants.UIBottomOfPagePadding)
                    }
                } else {
                    UniversalText( Constants.goalsSplashPurpose,
                                   size: Constants.UIDefaultTextSize,
                                   font: Constants.mainFont)
                }
            }
            .ignoresSafeArea()
            .tabViewStyle(.page(indexDisplayMode: .never))
            
        }
        .padding(7)
        .universalBackground()
        .sheet(isPresented: $showingGoalCreationView) { GoalCreationView.makeGoalCreationView(editing: false) }
    }
}
