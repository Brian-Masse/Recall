//
//  GoalsCharts.swift
//  Recall
//
//  Created by Brian Masse on 7/20/23.
//

import Foundation
import SwiftUI
import Charts


struct DataNode: Identifiable {
    var id: UUID = UUID()
    
    let date: Date
    let count: Double
    let category: String
    let goal: String
}

// This shows how many hours you spent doing something that contributed to a certain goal over time
struct ActivityPerDay: View {
    
    private let timePeriod = 7 * Constants.DayTime
    
    let title: String
    
    let goal: RecallGoal
    let events: [RecallCalendarEvent]
    let showYAxis: Bool 
    
    private func getData() -> [DataNode] {
        events.filter { event in event.startTime > .now - timePeriod }.compactMap { event in
            let count = event.getLengthInHours() * event.getGoalMultiplier(from: goal)
            return DataNode(date: event.startTime, count: count, category: "", goal: goal.label)
        }
    }
    
    private func collectDate(_ date: Date) -> Date {
        date.resetToStartOfDay()
    }
    
    var body: some View {
        
        let data = getData()
        VStack(alignment: .leading) {
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            
            Chart {
                ForEach(data) { datum in
                    BarMark(x: .value("date", datum.date, unit: .day ),
                            y: .value("count", datum.count))
                    .foregroundStyle(Colors.tint)
                    .cornerRadius(Constants.UIDefaultCornerRadius - 10)
                }
                
                RuleMark(y: .value("Goal", goal.targetHours) )
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]) )
                    .foregroundStyle(Colors.tint)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as( Date.self ) {
                        AxisValueLabel(centered: true) {
                            Text(date.formatted(.dateTime.day() ) )
                        }
                    }
                }
            }
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


struct TotalActivites: View {
    
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
                partialResult + (event.getLengthInHours() * event.getGoalMultiplier(from: goal))
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
            Chart {
                ForEach(data) { datum in
                    LineMark(x: .value("date", datum.date, unit: .day ),
                             y: .value("count", datum.count))
                    .foregroundStyle(Colors.tint)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]) )
                    
                    AreaMark(x: .value("X", datum.date, unit: .day ),
                             y: .value("Y", datum.count))
                    .foregroundStyle( LinearGradient(colors: [Colors.tint.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)  )
                    
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as( Date.self ) {
                        AxisValueLabel(centered: true) {
                            Text(date.formatted(.dateTime.day() ) )
                        }
                    }
                }
            }
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
