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
    }
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedRealmObject var goal: RecallGoal
    
    @State var showingGoalView: Bool = false
    
    let textFont: ProvidedFont = .renoMono
    
    let events: [RecallCalendarEvent]
    
    var body: some View {
        
        let completionData = goal.countGoalMet(from: events)
        let progressData = goal.getProgressTowardsGoal(from: events)
        
        VStack {
            
            HeadedBackground {
                HStack(alignment: .center) {
                    UniversalText( goal.label, size: Constants.UISubHeaderTextSize, font: .syneHeavy, true)
                    Spacer()
                    UniversalText( RecallGoal.GoalFrequence.getType(from: goal.frequency), size: Constants.UISmallTextSize, font: textFont )
                }
            } content: {
                VStack {
                    HStack {
                        UniversalText(goal.goalDescription, size: Constants.UISmallTextSize, font: textFont)
                            .frame(maxWidth: 80)
                        
                        makeSeperator()
                        
                        VStack(alignment: .trailing) {
                            UniversalText("completed", size: Constants.UISmallTextSize, font: textFont)
                            UniversalText("\(completionData.0)", size: Constants.UIHeaderTextSize, font: textFont)
                            
                            UniversalText("missed", size: Constants.UISmallTextSize, font: textFont)
                            UniversalText("\(completionData.1)", size: Constants.UIHeaderTextSize, font: textFont)
                        }
                        
                        makeSeperator()
                        
                        ActivityPerDay(goal: goal, events: events)
                            .frame(height: 100)

                    }
                }
                .padding()
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
                                .frame(width: min(Double(progressData) / Double(goal.targetHours) * geo.size.width, geo.size.width) )
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
                
                Spacer()
            }
        }
        .frame(height: 250)
        .onTapGesture { showingGoalView = true }
        .fullScreenCover(isPresented: $showingGoalView) { GoalView(goal: goal, events: events) }
    }
    
}
