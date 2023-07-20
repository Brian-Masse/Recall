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
    
    
    @State var showingGoalCreationView: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( "Productivity", size: Constants.UITitleTextSize, true )
            
            Spacer()
            
            UniversalText( "Goals", size: Constants.UIHeaderTextSize, true )
            
            ShortRoundedButton("Add Goal", icon: "gauge.medium.badge.plus") { showingGoalCreationView = true }
            
            ForEach( goals ) { goal in
                
                VStack {
                    HStack {
                        UniversalText( goal.label, size: Constants.UIDefaultTextSize, true )
                        Spacer()
                        UniversalText( "\(goal.frequency)", size: Constants.UIDefaultTextSize )
                        
                        
                    }
                    
                    ProgressView(value: goal.getCurrentProgressTowardsGoal(), total: 1)
                        .progressViewStyle(.linear)
                    
                    
                }
                
                
                .padding()
                .rectangularBackgorund()
                
            }
            
            Spacer()
            
        }.sheet(isPresented: $showingGoalCreationView) { GoalCreationView() }
    }
}
