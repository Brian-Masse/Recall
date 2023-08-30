//
//  GoalPreviewView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct GoalPreviewView: View {
    
    @ViewBuilder
    func makeSeperator() -> some View {
        Rectangle()
            .universalTextStyle()
            .frame(width: 1)
            .padding(.vertical)
    }
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedRealmObject var goal: RecallGoal
    @StateObject var dataModel: RecallGoalDataModel = RecallGoalDataModel()
    
    @State var showingGoalView: Bool = false
    @State var showingEditingView: Bool = false
    @State var showingDeletionAlert: Bool = false
    
    let textFont: ProvidedFont = .renoMono
    
    let events: [RecallCalendarEvent]
    
    @MainActor
    var body: some View {
        
        VStack {
            HStack(alignment: .center) {
                UniversalText( goal.label, size: Constants.UIHeaderTextSize, font: .syneHeavy, true)
                Spacer()
                UniversalText( RecallGoal.GoalFrequence.getType(from: goal.frequency), size: Constants.UISmallTextSize, font: textFont )
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 5)
            .universalTextStyle()
            
            VStack {
                HStack {
                    UniversalText(goal.goalDescription, size: Constants.UISmallTextSize, font: textFont)
                        .frame(maxWidth: 80)
                        .padding(.vertical)

                    makeSeperator()

                    VStack(alignment: .trailing) {
                        UniversalText("completed", size: Constants.UISmallTextSize, font: textFont)
                        UniversalText("\(dataModel.goalMetData.0)", size: Constants.UIHeaderTextSize, font: textFont)

                        UniversalText("missed", size: Constants.UISmallTextSize, font: textFont)
                        UniversalText("\(dataModel.goalMetData.1)", size: Constants.UIHeaderTextSize, font: textFont)
                    }

                    makeSeperator()

                    ActivityPerDay(recentData: true, title: "", goal: goal, events: events)
//                        .frame(height: 100)
                }
            }
            .padding(.horizontal)
            .frame(height: 70)

//            MARK: Progress Bar
            VStack {
                ZStack(alignment: .leading) {
                    GeometryReader { geo in

                        Rectangle()
                            .cornerRadius(Constants.UIDefaultCornerRadius)
                            .foregroundColor( colorScheme == .dark ? Colors.darkGrey : Colors.secondaryLightColor )

                        Rectangle()
                            .foregroundColor(Colors.tint)
                            .frame(width: max(min(dataModel.roundedProgressData / Double(goal.targetHours) * geo.size.width, geo.size.width),0) )
                            .cornerRadius(Constants.UIDefaultCornerRadius)
                    }
                }
                HStack {
                    UniversalText("current progress", size: Constants.UISmallTextSize, font: textFont)
                    Spacer()
                    UniversalText("\(dataModel.roundedProgressData) / \(goal.targetHours)", size: Constants.UISmallTextSize, font: textFont)
                }
            }
            .frame(height: 40)
            .padding(.horizontal)
            .padding(.bottom)

            Spacer()
        }
        .opaqueRectangularBackground(0, stroke: true)
        .onTapGesture { showingGoalView = true }
        .contextMenu {
            Button { showingEditingView = true }  label:          { Label("edit", systemImage: "slider.horizontal.below.rectangle") }
            Button(role: .destructive) { showingDeletionAlert = true } label:    { Label("delete", systemImage: "trash") }
        }
        .fullScreenCover(isPresented: $showingGoalView) { GoalView(goal: goal, events: events) }
        .sheet(isPresented: $showingEditingView) { GoalCreationView.makeGoalCreationView(editing: true, goal: goal) }
        .task { dataModel.makeData(for: goal, with: events) }
        .alert("Delete Goal?", isPresented: $showingDeletionAlert) {
            Button(role: .destructive) { goal.delete() } label:    { Label("delete", systemImage: "trash") }
        }
    }
    
}
