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
    
    @ViewBuilder
    func makeCircularProgressWidget(title: String, value: Int, total: Int) -> some View {
        
        VStack {
            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                .padding(.bottom, 5)
            CircularProgressView(currentValue: Float(value), totalValue: Float( total ))
        }
        .padding(5)
        .frame(width: 115)
        .secondaryOpaqueRectangularBackground()
        
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedRealmObject var goal: RecallGoal
    let events: [RecallCalendarEvent]
    
    @State var showingEditingScreen: Bool = false
    
    var body: some View {
        
        let progressData = goal.getProgressTowardsGoal(from: events)
        let averageData = goal.getAverage(from: events)
        let goalMetData = goal.countGoalMet(from: events)
        
        VStack(alignment: .leading) {
            HStack {
                UniversalText(goal.label, size: Constants.UITitleTextSize, font: Constants.titleFont, true)
                Spacer()
                LargeRoundedButton("", icon: "arrow.down") { presentationMode.wrappedValue.dismiss() }
            }
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    
                    UniversalText("overview", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                    
                    HStack {
                        UniversalText( goal.goalDescription, size: Constants.UISmallTextSize, font: Constants.mainFont )
                            .frame(width: 100)
                        
                        makeSeperator()
                        
                        VStack {
                            makeOverViewDataView(title: "priority", icon: "wallet.pass", data: goal.priority)
                            makeOverViewDataView(title: "period", icon: "calendar.day.timeline.leading", data: RecallGoal.GoalFrequence.getType(from: goal.frequency))
                            makeOverViewDataView(title: "goal", icon: "scope", data: "\(goal.targetHours)")
                        }
                    }
                    .secondaryOpaqueRectangularBackground()
                    .padding(.bottom)
                    
                    UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                    ScrollView(.horizontal) {
                        HStack {
                            LargeRoundedButton("edit", icon: "arrow.up.forward") { showingEditingScreen = true }
                            LargeRoundedButton("delete", icon: "arrow.up.forward") { goal.delete() }
                            LargeRoundedButton("change goal target", icon: "arrow.up.forward") { showingEditingScreen = true }
                        }
                    }
                    .secondaryOpaqueRectangularBackground()
                    .padding(.bottom)
                    
                    UniversalText("Goal Review", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                        .padding(.bottom)
                    
                    ScrollView(.horizontal) {
                        HStack {
                            makeCircularProgressWidget(title: "Current Progress", value: progressData, total: goal.targetHours)
                            
                            makeCircularProgressWidget(title: "Average Activity", value: Int(averageData), total: goal.targetHours)
                            
                            makeCircularProgressWidget(title: "Number of Times met", value: Int(goalMetData.0), total: goalMetData.1 + goalMetData.0)
                        }
                    }
                    
                    
                    VStack(alignment: .leading) {
                        UniversalText("Activties", size: Constants.UISubHeaderTextSize, font: Constants.titleFont, true)
                        ActivityPerDay(title: "activites per day", goal: goal, events: events, showYAxis: true)
                            .frame(height: 160)
                        
                        TotalActivites(title: "total activities", goal: goal, events: events, showYAxis: true)
                            .frame(height: 160)
                    }
                    .padding(5)
                    .secondaryOpaqueRectangularBackground()
                    
                }
            }
            Spacer()
        }
        .padding(7)
        .universalColoredBackground(Colors.tint)
        .sheet(isPresented: $showingEditingScreen) { GoalCreationView.makeGoalCreationView(editing: true, goal: goal) }
    }
    
}
