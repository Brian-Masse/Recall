//
//  GoalsDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/3/23.
//

import Foundation
import SwiftUI

struct GoalsDataSection: View {
    
    @MainActor
    private func makeGoalsMetOverTimeData() -> [DataNode] {
        var iterator = RecallModel.index.earliestEventDate
        var nodes : [DataNode] = []
        while iterator <= (.now + Constants.DayTime).resetToStartOfDay() {
//            for goal in goals { nodes.append(.init(date: iterator, count: 1, category: "", goal: goal.label)) }
            let count = goals.reduce(0) { partialResult, goal in partialResult + (goal.goalWasMet(on: iterator, events: events) ? 1 : 0) }
            nodes.append(.init(date: iterator, count: Double(count), category: "", goal: ""))
            
            iterator += Constants.DayTime
        }
        return nodes
    }
    
    @MainActor
    private func makeGoalsProgressOverTimeData() -> [DataNode] {
        var iterator = RecallModel.index.earliestEventDate
        var nodes: [DataNode] = []
        while iterator <= (.now + Constants.DayTime).resetToStartOfDay() {

            for goal in goals {
                let progress = 100 * (Double(goal.getProgressTowardsGoal(from: events, on: iterator)) / Double(goal.targetHours))
                nodes.append(.init(date: iterator, count: progress, category: "", goal: goal.label))
                
            }
            
            iterator += Constants.DayTime
        }
        return nodes
    }
    
    @MainActor
    private func makeAverageGoalActivityData() -> [DataNode] {
        let totalDays = RecallModel.getDaysSinceFirstEvent()
        return goals.compactMap { goal in
            let count = events.reduce(0) { partialResult, event in partialResult + event.getGoalPrgress(goal) } / totalDays
            return DataNode(date: .now, count: count, category: "", goal: goal.label)
        }
        
    }
    
    
    
    let events: [RecallCalendarEvent]
    let goals: [RecallGoal]
    
    var body: some View {
        
        LazyVStack(alignment: .leading) {
            let goalsMetOverTimeData = makeGoalsMetOverTimeData()
            let goalsProgressOverTime = makeGoalsProgressOverTimeData()
            let goalAverages = makeAverageGoalActivityData()
            
            DataCollection("Goals") {
                
                Seperator(orientation: .horizontal)
                LargeText(mainText: "\(goals.count)", subText: "goals")
                Seperator(orientation: .horizontal)
                    .padding(.bottom)
                
                GoalCompletionOverTime(data: goalsMetOverTimeData, unit: "")
                    .frame(height: 200)
                    .padding(.bottom, 5)
                
                GoalProgressOverTime(data: goalsProgressOverTime, unit: "%")
                    .frame(height: 200)
                
                GoalAverages(data: goalAverages, unit: "")
                
            }
        }.id( DataPageView.DataBookMark.Goals.rawValue )
    }
}
