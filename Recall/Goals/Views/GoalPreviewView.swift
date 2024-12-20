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
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    @State var showingDeletionAlert: Bool = false
    @Namespace private var namespace
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack(alignment: .center) {
            UniversalText( goal.label,
                           size: Constants.UISubHeaderTextSize,
                           font: Constants.titleFont)
            Spacer()
        }
    }
    
    @ViewBuilder
    private func makeMetaData() -> some View {
        HStack {
            makeMetaDataLabel(icon: "circle.badge.exclamationmark",
                              title: "\(goal.priority) Priority")
            
            makeMetaDataLabel(icon: "arrow.trianglehead.clockwise.rotate.90",
                              title: goal.getGoalFrequencyDescription())
            
            makeMetaDataLabel(icon: "gauge.with.needle",
                              title: goal.getTargetHoursDescription())
        }
        .frame(height: 30)
        .padding(.bottom)
    }
    
//    MARK: Body
    @MainActor
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                makeHeader()
                
                GoalView.GoalAnnualProgressView(goal: goal, includingFiltering: false)
                
//                makeSectionHeader("flag.pattern.checkered", title: "Current Progress")
//                GoalView.ProgressBarView(goal: goal)
            }
        }
        .safeZoomMatch(id: goal.id, namespace: namespace)
        .rectangularBackground(style: .primary)
        .onTapGesture { coordinator.push(.recallGoalEventView(goal: goal, id: goal.id, Namespace: namespace)) }
        .contextMenu {
            ContextMenuButton("edit", icon: "slider.horizontal.below.rectangle") { coordinator.presentSheet(.goalCreationView(editting: true, goal: goal)) }
            ContextMenuButton("delete", icon: "trash", role: .destructive) { showingDeletionAlert = true }
        }
        .task {
            goal.checkGoalDataStoreExists()
            await goal.dataStore!.setAllData()
            goal.checkColor()
        }
        .alert("Delete Goal?", isPresented: $showingDeletionAlert) {
            Button(role: .destructive) { goal.delete() } label:    { Label("delete", systemImage: "trash") }
        }
    }
}
