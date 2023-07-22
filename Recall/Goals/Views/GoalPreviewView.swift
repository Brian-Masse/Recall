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
    
    @State var showingGoalView: Bool = false
    @State var showingEditingView: Bool = false
    
    let textFont: ProvidedFont = .renoMono
    
    let events: [RecallCalendarEvent]
    
    var body: some View {
        
        let completionData = goal.countGoalMet(from: events)
        let progressData = goal.getProgressTowardsGoal(from: events)
        
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
                        UniversalText("\(completionData.0)", size: Constants.UIHeaderTextSize, font: textFont)
                        
                        UniversalText("missed", size: Constants.UISmallTextSize, font: textFont)
                        UniversalText("\(completionData.1)", size: Constants.UIHeaderTextSize, font: textFont)
                    }
                    
                    makeSeperator()
                    
                    ActivityPerDay(title: "", goal: goal, events: events, showYAxis: false)
                        .frame(height: 100)

                }
            }
            .padding(.horizontal)
            .frame(height: 110)
                
//            MARK: Progress Bar
            VStack {
                ZStack(alignment: .leading) {
                    GeometryReader { geo in
                        
                        Rectangle()
                            .cornerRadius(Constants.UIDefaultCornerRadius)
                            .foregroundColor( colorScheme == .dark ? Colors.darkGrey : Colors.lightGrey )
                        
                        Rectangle()
                            .foregroundColor(Colors.tint)
                            .frame(width: max(min(Double(progressData) / Double(goal.targetHours) * geo.size.width, geo.size.width),0) )
                            .cornerRadius(Constants.UIDefaultCornerRadius)
                    }
                }
                HStack {
                    UniversalText("current progress", size: Constants.UISmallTextSize, font: textFont)
                    Spacer()
                    UniversalText("\(progressData) / \(goal.targetHours)", size: Constants.UISmallTextSize, font: textFont)
                }
            }
            .frame(height: 40)
            .padding(.horizontal)
            .padding(.bottom)
                
            Spacer()
        }
        
        .background( colorScheme == .dark ? .black : .white )
        .cornerRadius(Constants.UILargeCornerRadius)
        .onTapGesture { showingGoalView = true }
        .contextMenu {
            Button("edit") { showingEditingView = true  }
            Button("delete") { goal.delete()  }
        }
        .fullScreenCover(isPresented: $showingGoalView) { GoalView(goal: goal, events: events) }
        .sheet(isPresented: $showingEditingView) {
            GoalCreationView(editing: true,
                             goal: goal,
                             label: goal.label,
                             description: goal.goalDescription,
                             frequence: RecallGoal.GoalFrequence.getRawType(from: goal.frequency),
                             targetHours: Float(goal.targetHours))
        }
    }
    
}
