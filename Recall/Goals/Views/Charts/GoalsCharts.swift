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

struct ActivitiesPerDay: View {
    
    let categories: [RecallCategory]
    let events = RecallCalendarEvent.getEvents()
    
//    @MainActor
//    private func getData() -> [DataNode] {
//        var dateIterator = RecallModel.index.earliestEventDate.resetToStartOfDay()
//        var list: [DataNode] = []
//        while dateIterator <= .now {
//            list.append(contentsOf: categories.compactMap { category in
//                let count = events.filter { event in event.startTime.matches(dateIterator, to: .day) && event.category?.label ?? "" == category.label }.count
//                return DataNode(date: dateIterator, count: count, category: category.label, goal: "")
//            })
//            dateIterator += Constants.DayTime
//        }
//        return list
//    }
    
    var body: some View {
        
        Text("hi")
//        let data = getData()
//
//        Chart {
//            ForEach( data ) { node in
//
//                BarMark(x: .value("Date", node.date),
//                        y: .value("CategoryCount", node.count))
//                .foregroundStyle(by: .value("categroy", node.category))
//            }
//        }
    }
}

// This shows how many hours you spent doing something that contributed to a certain goal over time
struct ActivityPerDay: View {
    
    private let timePeriod = 7 * Constants.DayTime
    
    let goal: RecallGoal
    let events: [RecallCalendarEvent]
    
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
        
        Chart {
            ForEach(data) { datum in
                BarMark(x: .value("date", datum.date, unit: .day ),
                        y: .value("count", datum.count))
                .foregroundStyle(Colors.tint)
                .cornerRadius(Constants.UIDefaultCornerRadius)
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
                    AxisValueLabel( "\(count) HR" )
                }
            }
        }
        
    }
    
}
