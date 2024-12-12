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
//    @StateObject var dataModel: RecallGoalDataStore = RecallGoalDataStore()
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    @State var showingDeletionAlert: Bool = false
    @Namespace private var namespace
    
    let events: [RecallCalendarEvent]
    
//    MARK: ViewModifiers
    
    
        
//    MARK: Header
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
    
//    MARK: MetaData
//    @ViewBuilder
//    private func makeMetaData() -> some View {
//        VStack {
//            HStack {
//                VStack(alignment: .trailing) {
//                    UniversalText("completed",
//                                  size: Constants.UISmallTextSize,
//                                  font: Constants.mainFont)
//                    UniversalText("\(dataModel.goalMetData.0)",
//                                  size: Constants.UIHeaderTextSize,
//                                  font: Constants.titleFont)
//
//                    UniversalText("missed",
//                                  size: Constants.UISmallTextSize,
//                                  font: Constants.mainFont)
//                    UniversalText("\(dataModel.goalMetData.1)",
//                                  size: Constants.UIHeaderTextSize,
//                                  font: Constants.titleFont)
//                }
//                .opacity(0.75)
//
//
//                ActivityPerDay(recentData: true, title: "", goal: goal, data: dataModel.recentProgressOverTimeData)
////                    .padding()
////                    .background(RoundedRectangle( cornerRadius: Constants.UIDefaultCornerRadius).stroke().foregroundStyle(.background) )
//                    .padding(.horizontal, 7)
//            }
//        }
//    }
    
//    MARK: ProgressBar
//    @ViewBuilder
//    private func makeProgressBar() -> some View {
//        ZStack(alignment: .leading) {
//            GeometryReader { geo in
//
//                Rectangle()
//                    .universalStyledBackgrond(.primary, onForeground: true)
//                    .cornerRadius(Constants.UIDefaultCornerRadius)
//                
//                Rectangle()
//                    .universalStyledBackgrond(.accent, onForeground: true)
//                    .frame(width: max(min(dataModel.roundedProgressData / Double(goal.targetHours) * geo.size.width, geo.size.width),0) )
//                    .cornerRadius(Constants.UIDefaultCornerRadius)
//            }
//        }.frame(height: 20)
//        
//        HStack {
//            UniversalText("current progress",
//                          size: Constants.UISmallTextSize,
//                          font: Constants.mainFont)
//            Spacer()
//            UniversalText("\(dataModel.roundedProgressData) / \(goal.targetHours)",
//                          size: Constants.UISmallTextSize,
//                          font: Constants.mainFont)
//        }
//    }
    
//    MARK: Body
    @MainActor
    var body: some View {
        VStack {
//            if dataModel.dataLoaded {
            VStack(alignment: .leading) {
                makeHeader()
                
//                makeMetaData()
//                    .padding(.bottom)
            }
            .rectangularBackground(style: .secondary, stroke: true)
            .onTapGesture { coordinator.push(.recallGoalEventView(goal: goal, id: goal.id, Namespace: namespace)) }
            .contextMenu {
                ContextMenuButton("edit", icon: "slider.horizontal.below.rectangle") { coordinator.presentSheet(.goalCreationView(editting: true, goal: goal)) }
                ContextMenuButton("delete", icon: "trash", role: .destructive) { showingDeletionAlert = true }
            }
//            } else {
//                LoadingView(height: 220)
//            }
        }
//        .task { await dataModel.makeData(for: goal, with: events) }
        .task {
            goal.checkGoalDataStoreExists()
            await goal.dataStore!.setAllData()
        }
        .alert("Delete Goal?", isPresented: $showingDeletionAlert) {
            Button(role: .destructive) { goal.delete() } label:    { Label("delete", systemImage: "trash") }
        }
    }
    
}
