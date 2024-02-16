//
//  GoalPreviewView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

struct GoalPreviewView: View {
    
//    MARK: Vars
    @ObservedRealmObject var goal: RecallGoal
    @StateObject var dataModel: RecallGoalDataModel = RecallGoalDataModel()
    
    @State var showingGoalView: Bool = false
    @State var showingEditingView: Bool = false
    @State var showingDeletionAlert: Bool = false
    
    let events: [RecallCalendarEvent]
    
//    MARK: ViewModifiers
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack(alignment: .center) {
            UniversalText( goal.label,
                           size: Constants.UIHeaderTextSize,
                           font: Constants.titleFont)
            Spacer()
            UniversalText( RecallGoal.GoalFrequence.getType(from: goal.frequency),
                           size: Constants.UISmallTextSize,
                           font: Constants.mainFont )
        }
    }
    
    @ViewBuilder
    private func makeMetaData() -> some View {
        VStack {
            HStack {
                UniversalText(goal.goalDescription,
                              size: Constants.UISmallTextSize,
                              font: Constants.mainFont)
                    .frame(maxWidth: 80)
                    .padding(.vertical)

                Divider(vertical: true)

                VStack(alignment: .trailing) {
                    UniversalText("completed",
                                  size: Constants.UISmallTextSize,
                                  font: Constants.mainFont)
                    UniversalText("\(dataModel.goalMetData.0)",
                                  size: Constants.UIHeaderTextSize,
                                  font: Constants.mainFont)

                    UniversalText("missed",
                                  size: Constants.UISmallTextSize,
                                  font: Constants.mainFont)
                    UniversalText("\(dataModel.goalMetData.1)",
                                  size: Constants.UIHeaderTextSize,
                                  font: Constants.mainFont)
                }

                Divider(vertical: true)

                ActivityPerDay(recentData: true, title: "", goal: goal, data: dataModel.recentProgressOverTimeData)
            }
        }
        .frame(height: 80)
    }
    
    @ViewBuilder
    private func makeProgressBar() -> some View {
        ZStack(alignment: .leading) {
            GeometryReader { geo in

                HStack { Spacer() }
                    .rectangularBackground(style: .secondary)
                
                Rectangle()
                    .universalStyledBackgrond(.accent, onForeground: true)
                    .frame(width: max(min(dataModel.roundedProgressData / Double(goal.targetHours) * geo.size.width, geo.size.width),0) )
                    .cornerRadius(Constants.UIDefaultCornerRadius)
            }
        }.frame(height: 40)
        
        HStack {
            UniversalText("current progress",
                          size: Constants.UISmallTextSize,
                          font: Constants.mainFont)
            Spacer()
            UniversalText("\(dataModel.roundedProgressData) / \(goal.targetHours)",
                          size: Constants.UISmallTextSize,
                          font: Constants.mainFont)
        }
    }
    
//    MARK: Body
    @MainActor
    var body: some View {
        VStack {
            
            makeHeader()
                .padding(.bottom, 7)
        
            makeMetaData()
                .padding(.bottom, 7)

            makeProgressBar()
            
            Spacer()
        }
        .rectangularBackground(style: .primary, stroke: true)
        .onTapGesture { showingGoalView = true }
        .contextMenu {
            Button { showingEditingView = true }  label:          { Label("edit", systemImage: "slider.horizontal.below.rectangle") }
            Button(role: .destructive) { showingDeletionAlert = true } label:    { Label("delete", systemImage: "trash") }
        }
        .fullScreenCover(isPresented: $showingGoalView) {
            GoalView(goal: goal, events: events)
                .environmentObject(dataModel)
        }
        .sheet(isPresented: $showingEditingView) { GoalCreationView.makeGoalCreationView(editing: true, goal: goal) }
        .task { await dataModel.makeData(for: goal, with: events) }
        .alert("Delete Goal?", isPresented: $showingDeletionAlert) {
            Button(role: .destructive) { goal.delete() } label:    { Label("delete", systemImage: "trash") }
        }
    }
    
}
