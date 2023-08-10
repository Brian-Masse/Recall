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
    
//    This returns 2 lists, the first is the total progress for each goal, and the other is how many time that progress was met
//    This data can then by used to inexpensivly compute the average when graphing
    @MainActor
    private func makeCountedData() -> ([DataNode], [DataNode]) {
        var metCount: [DataNode] = []
        var progress: [DataNode] = []
        let start: (Double, Double) = (0,0)
        
        for goal in goals {
            events.reduce
            let counts = events.reduce( into: start ) { partialResult, event in
                var tuple = partialResult
                tuple.0 += event.getGoalPrgress(goal)
                tuple.1 += goal.goalWasMet(on: event.startTime, events: events) ? 1 : 0
                return tuple
            }
            progress.append(.init(date: .now, count: counts.0, category: "", goal: goal.label))
            metCount.append(.init(date: .now, count: counts.1, category: "", goal: goal.label))
        }
        
        return (progress, metCount)
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
                    .padding(.bottom)
                
                GoalProgressOverTime(data: goalsProgressOverTime, unit: "%")
                    .frame(height: 200)
                    .padding(.bottom)
                
                GoalAverages(data: goalAverages, unit: "HR")
                
            }
        }.id( DataPageView.DataBookMark.Goals.rawValue )
    }
}
