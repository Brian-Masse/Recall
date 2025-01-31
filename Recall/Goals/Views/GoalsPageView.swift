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

//MARK: GoalsPageView
struct GoalsPageView: View {

    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    let goals: [RecallGoal]
    
//    MARK: makeGoalsSection
    private struct GoalsSection: View {
        private func getGoals() async {
            if !self.goals.isEmpty { return }
            
            let goals: [RecallGoal] = RealmManager.retrieveObjectsInList()
                .filter { goal in goal.priority == priority.rawValue }
            
            self.goals = goals
        }
        
        init( showingSection: Bool, priority: RecallGoal.Priority ) {
            self.showingSection = showingSection
            self.defaultShowingStatus = showingSection
            self.priority = priority
        }
        
        @State private var goals: [RecallGoal] = []
        @State private var showingSection: Bool
        
        private let defaultShowingStatus: Bool
        private let priority: RecallGoal.Priority
        
        var body: some View {
            VStack {
                UniversalButton {
                    HStack {
                        UniversalText( priority.rawValue + " priority",
                                       size: Constants.UISubHeaderTextSize,
                                       font: Constants.titleFont )
                        
                        Spacer()
                        
                        RecallIcon(showingSection ? "chevron.down" : "chevron.up")
                    }
                } action: { showingSection.toggle() }
                
                if showingSection  {
                    if goals.count > 0 {
                        VStack {
                            ForEach( goals, id: \.self ) { goal in
                                GoalPreviewView(goal: goal)
                                    .transition(.blurReplace)
                            }
                        }.rectangularBackground(7, style: .secondary, stroke: true)
                    } else {
                        makeSectionFiller(icon: "flag.slash",
                                          message: "No \(priority.rawValue) priority goals. Create or edit a goal's priorty to see it here.") {}
                    }
                }
            }
            .animation(.easeInOut, value: goals.count)
            .task { await getGoals() }
            .onDisappear { showingSection = defaultShowingStatus }
        }
    }
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            UniversalText( "Goals", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
            Spacer()
            
            IconButton("plus", label: "Add Goal") { coordinator.presentSheet(.goalCreationView(editting: false)) }
        }
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                makeHeader()
                
                if goals.count != 0{
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack {
                            ForEach( RecallGoal.Priority.allCases) { priority in
                                let showSection: Bool = priority == RecallGoal.Priority.high
                                GoalsSection(showingSection: showSection,
                                             priority: priority)
                                    .padding(.bottom, 30)
                            }
                        }
    
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: 140)
                    }
                    
                } else {
                    UniversalText( Constants.goalsSplashPurpose,
                                   size: Constants.UIDefaultTextSize,
                                   font: Constants.mainFont)
                }
            }
        }
        .padding(7)
        .universalBackground()
    }
}
