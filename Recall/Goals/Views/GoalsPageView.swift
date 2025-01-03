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
        
        @State private var goals: [RecallGoal] = []
        @State var showingSection: Bool
        
        let priority: RecallGoal.Priority
        
        var body: some View {
            VStack {
                if goals.count != 0 {
                    UniversalButton {
                        HStack {
                            UniversalText( priority.rawValue + " priority",
                                           size: Constants.UISubHeaderTextSize,
                                           font: Constants.titleFont )
                            
                            Spacer()
                            
                            RecallIcon(showingSection ? "chevron.down" : "chevron.up")
                        }
                    } action: { showingSection.toggle() }
                    
                    if showingSection {
                        VStack {
                            ForEach( goals, id: \.self ) { goal in
                                GoalPreviewView(goal: goal)
                                    .transition(.blurReplace)
                            }
                        }.rectangularBackground(7, style: .secondary, stroke: true)
                    }
                }
            }
            .animation(.easeInOut, value: goals.count)
            .task { await getGoals() }
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
