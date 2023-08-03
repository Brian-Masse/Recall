//
//  EventsDataSection.swift
//  Recall
//
//  Created by Brian Masse on 8/2/23.
//

import Foundation
import SwiftUI
import Charts

struct EventsDataSection: View {
    
    let events: [RecallCalendarEvent]
    
    private func makeData(dataAggregator: (RecallCalendarEvent) -> Double) -> [DataNode] {
        events.compactMap { event in
            DataNode(date: event.startTime, count: dataAggregator(event), category: event.getTagLabel(), goal: "")
        }.sorted { node1, node2 in node1.category < node2.category }
    }
    
//    THis merges data points that all have the same tag
    private func compressData(from data: [DataNode]) -> [DataNode] {
        Array( data.reduce(Dictionary<String, DataNode>()) { partialResult, node in
            let key = node.category
            var mutable = partialResult
            if var value = mutable[ key ] {
                mutable[key] = value.increment(by: node.count )
            } else { mutable[key] = .init(date: .now, count: node.count, category: key, goal: "") }
            return mutable
        }.values ).sorted { node1, node2 in node1.count < node2.count }
    }
    
//    period is measured in days
//    This is purely convenience
    private func getRecentData(from data: [DataNode], in period: Double = 7) -> [DataNode] {
        data.filter { node in node.date >= .now.resetToStartOfDay() - (period * Constants.DayTime) }
    }
    
    var body: some View {
    
//        These are typically used for the charts
        let hourlyData = makeData { event in event.getLengthInHours() }
//        in general the compressed data is used for data sumarries, that dont need every individaul node
        let compressedHourlyData = compressData(from: hourlyData)
        
        let recentHourlyData = getRecentData(from: hourlyData)
        let compressedRecentHourlyData = getRecentData(from: compressedHourlyData)
        
        
        let tagData = makeData { _ in 1 }
        let compressedTagData = compressData(from: tagData)
        let recentTagData = getRecentData(from: tagData)
        let compressedRecentTagData = getRecentData(from: compressedTagData)
        
        DataCollection("Events") {
            
            Group {
                
                AverageActivityByTag(data: recentHourlyData, unit: "")
                EventsDataSummaries.DailyAverage(data: compressedHourlyData, unit: "HR/DY")
                    .padding(.bottom)
                
                ActivitiesPerDay("Hours per day, by tag", data: recentHourlyData)
                EventsDataSummaries.SuperlativeEvents(data: compressedRecentHourlyData, unit: "HR")
                EventsDataSummaries.ActivityPerTag(data: compressedRecentTagData, unit: "HR")
                    .padding(.bottom)
                
                ActivitiesPerDay("Events per day, by tag", data: recentTagData)
                EventsDataSummaries.SuperlativeEvents(data: compressedRecentTagData, unit: "")
                EventsDataSummaries.ActivityPerTag(data: compressedRecentTagData, unit: "")
                
            }
            .hideableDataCollection("This week", largeTitle: true)
            .padding(.bottom, 20)
            
            Group {
                ActivitiesPerDay("Hours per day, by tag", data: hourlyData, scrollable: true)
                    .frame(height: 250)
                EventsDataSummaries.SuperlativeEvents(data: compressedHourlyData, unit: "HR")
                EventsDataSummaries.ActivityPerTag(data: compressedHourlyData, unit: "HR")
                    .padding(.bottom)
                
                ActivitiesPerDay("Events per day, by tag", data: tagData, scrollable: true)
                    .frame(height: 250)
                EventsDataSummaries.SuperlativeEvents(data: compressedTagData, unit: "")
                EventsDataSummaries.ActivityPerTag(data: compressedTagData, unit: "")
                
            }.hideableDataCollection("All Time", largeTitle: true)
            
            
            
        }.id( DataPageView.DataBookMark.Events.rawValue )
        
        
    }
    
}
