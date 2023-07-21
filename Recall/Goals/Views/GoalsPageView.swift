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
            }.padding(7)
            
            ScrollView(.vertical) {
                ForEach( goals ) { goal in
                    GoalPreviewView(goal: goal, events: events)
                        .padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showingGoalCreationView) { GoalCreationView() }
    }
}
