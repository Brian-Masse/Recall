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
    
//    MARK: Helpers
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
    func makeCircularProgressWidget(title: String, value: Double, total: Double) -> some View {
        
        VStack {
            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                .padding(.bottom, 5)
            CircularProgressView(currentValue: value, totalValue: total)
        }
        .padding(5)
        .frame(width: 115)
        .secondaryOpaqueRectangularBackground()
        
    }
    
//    MARK: vars
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedResults(RecallCategory.self) var tags
    @ObservedRealmObject var goal: RecallGoal
    @EnvironmentObject var dataModel: RecallGoalDataModel
    
    let events: [RecallCalendarEvent]
    
    @State var showingEditingScreen: Bool = false
    @State var showingDeletionAlert: Bool = false
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeOverview() -> some View {
        UniversalText("overview", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
        
        HStack {
            UniversalText( goal.goalDescription, size: Constants.UISmallTextSize, font: Constants.mainFont )
                .frame(width: 100)
            
            makeSeperator()
            
            VStack {
                makeOverViewDataView(title: "priority", icon: "exclamationmark.triangle", data: goal.priority)
                makeOverViewDataView(title: "period", icon: "calendar.day.timeline.leading", data: RecallGoal.GoalFrequence.getType(from: goal.frequency))
                makeOverViewDataView(title: "goal", icon: "flag.checkered", data: "\(goal.targetHours) \(goal.byTag() ? "tags" : "HR")")
                makeOverViewDataView(title: "created on", icon: "calendar.badge.clock", data: "\(goal.creationDate.formatted(date: .numeric, time: .omitted))")
            }
        }
        .secondaryOpaqueRectangularBackground()
        .padding(.bottom)
    }
    
    @ViewBuilder
    private func makeContributingTags() -> some View {
        let contributingTags = tags.filter { tag in tag.worksTowards(goal: goal) }
        
        if contributingTags.count != 0 {
            UniversalText("Contributing Tags", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
            
            WrappedHStack(collection: Array(contributingTags)) { tag in
                HStack {
                    Image(systemName: "arrow.up.right")
                    UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                    
                }.opaqueRectangularBackground()
            }
            .secondaryOpaqueRectangularBackground(7)
        }
    }
    
    @ViewBuilder
    private func makeQuickActions() -> some View {
        UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
        ScrollView(.horizontal) {
            HStack {
                LargeRoundedButton("edit", icon: "arrow.up.forward") { showingEditingScreen = true }
                LargeRoundedButton("delete", icon: "arrow.up.forward") { showingDeletionAlert = true }
                LargeRoundedButton("change goal target", icon: "arrow.up.forward") { showingEditingScreen = true }
            }
        }
        .secondaryOpaqueRectangularBackground(7)
        .padding(.bottom)
    }
    
    @ViewBuilder
    private func makeGoalReview() -> some View {
        
        let progressData = dataModel.progressData
        let averageData = dataModel.averageData
        let goalMetData = dataModel.goalMetData
        
        UniversalText("Goal Review", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
            .padding(.bottom)
        
        ScrollView(.horizontal) {
            HStack {
                makeCircularProgressWidget(title: "Current Progress", value: progressData, total: Double(goal.targetHours))
                
                makeCircularProgressWidget(title: "Average Activity", value: averageData, total: Double(goal.targetHours))
                
                makeCircularProgressWidget(title: "Number of Times met", value: Double(goalMetData.0), total: Double(goalMetData.1 + goalMetData.0))
            }
        }
        
//
        ActivityPerDay(recentData: false, title: "activites per day", goal: goal, data: dataModel.progressOverTimeData)
            .frame(height: 160)
            .padding(5)
            .secondaryOpaqueRectangularBackground()

        TotalActivites(title: "total activities", goal: goal, events: events, showYAxis: true)
            .frame(height: 160)
            .padding(5)
            .secondaryOpaqueRectangularBackground()
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                UniversalText(goal.label, size: Constants.UITitleTextSize, font: Constants.titleFont, true)
                Spacer()
                LargeRoundedButton("", icon: "arrow.down") { presentationMode.wrappedValue.dismiss() }
            }
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    
                    makeOverview()
                    
                    makeQuickActions()

                    makeGoalReview()
                    
                    makeContributingTags()
                }
            }
            Spacer()
        }
        .padding(7)
        .universalBackground()
        .sheet(isPresented: $showingEditingScreen) { GoalCreationView.makeGoalCreationView(editing: true, goal: goal) }
//        .onAppear { dataModel.makeData(for: goal, with: events) }
        .alert("Delete Goal?", isPresented: $showingDeletionAlert) {
            Button(role: .destructive) { goal.delete() } label:    { Label("delete", systemImage: "trash") }
        }
    }
    
    
}
