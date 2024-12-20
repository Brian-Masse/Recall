//
//  GoalsCharts.swift
//  Recall
//
//  Created by Brian Masse on 7/20/23.
//

import Foundation
import SwiftUI
import Charts
import UIUniversals


//MARK: DataNode
struct DataNode: Identifiable {
    var id: UUID = UUID()
    
    let date: Date
    var count: Double
    let category: String
    let goal: String
    
    mutating func changeCount(to newVal: Double) -> DataNode {
        self.count = newVal
        return self
    }
    
    mutating func increment(by increment: Double) -> DataNode {
        self.count += increment
        return self
    }
    
//    MARK: Conveineince Functions
    
    @MainActor
    private func getGoal() -> RecallGoal? {
        RealmManager.retrieveObjectsInResults { goal in
             goal.label.equals(self.goal)
        }.first
    }
    
    @MainActor
    func getDaysSinceGoalCreation() -> Double {
        if let goal = self.getGoal() {
            return Double(Date.now.timeIntervalSince(goal.creationDate)) / Constants.DayTime
        } else {
            return Double(RecallModel.index.daysSinceFirstEvent())
        }
    }
}

//MARK: ActivityPerDay
// This shows how many hours you spent doing something that contributed to a certain goal over time
struct ActivityPerDay: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let recentData: Bool
    let title: String
    
    let goal: RecallGoal
    let data: [DataNode]
    
    @MainActor
    @ViewBuilder
    private func makeChart() -> some View {
        
        Chart {
            ForEach(data) { datum in
                BarMark(x: .value("date", datum.date, unit: .day ),
                        y: .value("count", datum.count), width: Constants.UIScrollableBarWidth)
                .cornerRadius(Constants.UIDefaultCornerRadius - 10)
                .foregroundStyle(Colors.getAccent(from: colorScheme))
            }

            RuleMark(y: .value("Goal", goal.targetHours) )
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]) )
                .foregroundStyle(Colors.getAccent(from: colorScheme))
        }
        .if(!recentData) { view in view.reversedXAxis() }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if value.index == 0 { AxisGridLine() }
                
                if let date = value.as( Date.self ) {
                    
                    let dateLabel = "\(date.formatted(.dateTime.day(.twoDigits)))"
                    
                    AxisValueLabel {
                        UniversalText( dateLabel, size: Constants.UISmallTextSize, font: Constants.mainFont )
                    }
//
                    if date.matches(goal.creationDate, to: .day) {
                        AxisGridLine(centered: true, stroke: .init(lineWidth: 1, lineCap: .round, dash: [2, 6]))
                            .foregroundStyle(.red)
                        
                    }
                }
            }
        }
        .chartYAxis {
            
            AxisMarks(position: .leading, values: .stride(by: 20)) { value in
                if let count = value.as(Int.self) {
                    if !recentData {
                        AxisValueLabel( "\(count) HR" )
                    }
                    
                    if count == 0 {
                        AxisGridLine()
                    }
                }
            }
        }
    }
    
//    MARK: Body
        
    var body: some View {
    
        VStack(alignment: .leading) {
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            
            if recentData {
                makeChart()
            } else {
                ScrollChart(Int(RecallModel.index.daysSinceFirstEvent())) {
                    makeChart()
                }
            }
        }
    }
}


//MARK: TotalActivites
struct TotalActivites: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    
    let goal: RecallGoal
    let events: [RecallCalendarEvent]
    let showYAxis: Bool
    
    @MainActor
    private func getData() -> [DataNode] {
        var nodes: [DataNode] = []
        var dateIterator = goal.getStartDate()
        while dateIterator <= .now {
            let count = events.filter { event in event.startTime.matches(dateIterator, to: .day) }.reduce(0) { partialResult, event in
                partialResult + event.getGoalProgressThreadInvariant(goal)
            }
            nodes.append(DataNode(date: dateIterator, count: (nodes.last?.count ?? 0) + count, category: "", goal: goal.label))
            dateIterator += Constants.DayTime
        }
        return nodes
    }

    var body: some View {
        
        let data = getData()
        
        VStack(alignment: .leading) {
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            ScrollChart(Int(RecallModel.index.daysSinceFirstEvent())) {
                Chart {
                    ForEach(data) { datum in
                        LineMark(x: .value("date", datum.date, unit: .day ),
                                 y: .value("count", datum.count))
                        .foregroundStyle(Colors.getAccent(from: colorScheme))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]) )
                        
                        
                        AreaMark(x: .value("X", datum.date, unit: .day ),
                                 y: .value("Y", datum.count))
                        .foregroundStyle( LinearGradient(colors: [Colors.getAccent(from: colorScheme).opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)  )
                        
                    }
                }
                .chartOverTimeXAxis()
                .chartYAxis {
                    AxisMarks { value in
                        if let count = value.as(Int.self) {
                            if showYAxis { AxisValueLabel( "\(count) HR" ) }
                        }
                    }
                }
            }
        }
    }
}
