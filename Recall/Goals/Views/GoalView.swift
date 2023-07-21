//
//  GoalView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct GoalView: View {
    
    @ViewBuilder
    func makeSeperator() -> some View {
        Rectangle()
            .universalTextStyle()
            .frame(width: 1)
    }
    
    @ViewBuilder
    func makeOverViewDataView(title: String, icon: String, data: String) -> some View {
        
        HStack {
            Image(systemName: icon)
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont, true)
            
            Spacer()
            UniversalText(data, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        }
        
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedRealmObject var goal: RecallGoal
    let events: [RecallCalendarEvent]
    
    @State var showingEditingScreen: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                UniversalText(goal.label, size: Constants.UITitleTextSize, font: Constants.titleFont, true)
                Spacer()
                LargeRoundedButton("Edit", icon: "") { showingEditingScreen = true }
                LargeRoundedButton("", icon: "arrow.down") { presentationMode.wrappedValue.dismiss() }
            }
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    
                    UniversalText("overview", size: Constants.UISubHeaderTextSize, font: Constants.titleFont, true)
                    
                    HStack {
                        UniversalText( goal.goalDescription, size: Constants.UISmallTextSize, font: Constants.mainFont )
                            .frame(width: 100)
                        
                        makeSeperator()
                        
                        VStack {
                            makeOverViewDataView(title: "tag", icon: "wallet.pass", data: "test")
                            makeOverViewDataView(title: "period", icon: "calendar.day.timeline.leading", data: RecallGoal.GoalFrequence.getType(from: goal.frequency))
                            makeOverViewDataView(title: "goal", icon: "scope", data: "\(goal.targetHours)")
                        }
                    }
                }
                .secondaryOpaqueRectangularBackground()
                .padding(.bottom)
                
                UniversalText("Goal Review", size: Constants.UITitleTextSize, font: Constants.titleFont, true)
                    .padding(.bottom)
                
                ActivityPerDay(goal: goal, events: events)
                    .frame(height: 200)
                
                
            }
            Spacer()
        }
        .padding()
        .universalBackground()
        .sheet(isPresented: $showingEditingScreen) {
            GoalCreationView(editing: true,
                             goal: goal,
                             label: goal.label,
                             description: goal.goalDescription,
                             frequence: RecallGoal.GoalFrequence.getRawType(from: goal.frequency),
                             targetHours: Float(goal.targetHours))
            
        }
    }
    
}
