//
//  GoalsDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/3/23.
//

import Foundation
import SwiftUI

struct GoalsDataSection: View {
    
//    MARK: Data Aggregators
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
    
//  The first is the progress over time, the second is the number of times the goal was met
    @MainActor
    private func makeGoalsProgressOverTimeData() -> ([DataNode], [DataNode]) {
        var iterator = RecallModel.index.earliestEventDate
        var progress: [DataNode] = []
        var timesMet: [DataNode] = []
        
        while iterator <= (.now + Constants.DayTime).resetToStartOfDay() {
            for goal in goals {
                let progressNum = 100 * (Double(goal.getProgressTowardsGoal(from: events, on: iterator)) / Double(goal.targetHours))
                let met = goal.goalWasMet(on: iterator, events: events)
                
                progress.append(.init(date: iterator, count: progressNum, category: "", goal: goal.label))
                timesMet.append(.init(date: iterator, count: met ? 1 : 0, category: "", goal: goal.label))
                
            }
            
            iterator += Constants.DayTime
        }
        return ( progress, timesMet )
    }
    
//    This returns 2 lists, the first is the total progress for each goal, and the other is how many time that progress was met
//    This data can then by used to inexpensivly compute the average when graphing
    @MainActor
    private func makeCountedData() -> ([DataNode], [DataNode]) {
        var metCount: [DataNode] = []
        var progress: [DataNode] = []
        
        for goal in goals {
            
            let counts = events.reduce([0,0]) { partialResult, event in
                var list = partialResult
                list[0] += event.getGoalPrgress(goal)
                list[1] += goal.goalWasMet(on: event.startTime, events: events) ? 1 : 0
                return list
            }
            progress.append(.init(date: .now, count: counts[0], category: "", goal: goal.label))
            metCount.append(.init(date: .now, count: counts[1], category: "", goal: goal.label))
        }
        return (progress, metCount)
    }
    
    @MainActor
    private func makeCompletionPercentageData() -> [DataNode] {
        goals.compactMap { goal in
            let data = goal.countGoalMet(from: events)
            let percentage = 100 * (Double(data.0) / Double(data.1 + data.0))
            return .init(date: .now, count: percentage, category: "", goal: goal.label)
        }
    }
    
    
    
    let events: [RecallCalendarEvent]
    let goals: [RecallGoal]
    
//    MARK: Body
    var body: some View {
        
        LazyVStack(alignment: .leading) {
            lazy var goalsMetOverTimeData = makeGoalsMetOverTimeData()
            lazy var countsOverTime = makeGoalsProgressOverTimeData()
            lazy var progressOverTime = countsOverTime.0
            lazy var metOverTime = countsOverTime.1
            
            lazy var countData = makeCountedData()
            lazy var progressData = countData.0
            lazy var metData = countData.1
            lazy var totalGoalsMet = metData.reduce(0) { partialResult, node in partialResult + node.count }
            
            lazy var metPercentageData = makeCompletionPercentageData()
            
            DataCollection("Goals") {
                
                Seperator(orientation: .horizontal)
                LargeText(mainText: "\(goals.count)", subText: "goals")
                Seperator(orientation: .horizontal)
                    .padding(.bottom)
                
                Group {
                    UniversalText("Goals Over Time", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                    
                    GoalCompletionOverTime(data: goalsMetOverTimeData, unit: "")
                        .frame(height: 200)
                        .padding(.bottom)
                    
                    GoalProgressOverTime(data: progressOverTime, unit: "%")
                        .frame(height: 200)
                        .padding(.bottom)
                    
                    GoalProgressOverTime(data: metOverTime, unit: "")
                        .frame(height: 200)
                        .padding(.bottom)
                }
                
                Seperator(orientation: .horizontal)
                    .padding(.bottom)
                    
                Group {
                    UniversalText("Counts", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                        .padding(.bottom)
                    
                    GoalAverages(title: "Goal Progress", data: progressData, unit: "")
                        .padding(.bottom)
                    
                    GoalAverages(title: "Times Met", data: metData, unit: "")
                        .padding(.bottom)
                    
                    GoalsDataSummaries.GoalsMetCount(data: metData)
                    
                    Seperator(orientation: .horizontal)
                    LargeText(mainText: "\(Int(totalGoalsMet))", subText: "Goals met")
                    Seperator(orientation: .horizontal)
                        .padding(.bottom)
                }
                
                Group {
                    GoalsMetPercentageChart(title: "Goals Met Percentage", data: metPercentageData, unit: "%")
                    
                    GoalsDataSummaries.GoalsMetPercentageBreakdown(data: metPercentageData)
                        .padding(.bottom)
                }
            }
        }.id( DataPageView.DataBookMark.Goals.rawValue )
    }
}
