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
    let count: Int
    let category: String
    let goal: String
}

struct ActivitiesPerDay: View {
    
    let categories: [RecallCategory]
    let events = RecallCalendarEvent.getEvents()
    
    @MainActor
    private func getData() -> [DataNode] {
        var dateIterator = RecallModel.index.earliestEventDate.resetToStartOfDay()
        var list: [DataNode] = []
        while dateIterator <= .now {
            list.append(contentsOf: categories.compactMap { category in
                let count = events.filter { event in event.startTime.matches(dateIterator, to: .day) && event.category?.label ?? "" == category.label }.count
                return DataNode(date: dateIterator, count: count, category: category.label, goal: "")
            })
            dateIterator += Constants.DayTime
        }
        return list
    }
    
    var body: some View {
        
        let data = getData()
        
        Chart {
            ForEach( data ) { node in
                
                BarMark(x: .value("Date", node.date),
                        y: .value("CategoryCount", node.count))
                .foregroundStyle(by: .value("categroy", node.category))
            }
        }
    }
    
}
