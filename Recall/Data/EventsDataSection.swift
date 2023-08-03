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
    
    private func getTotalHours(from data: [DataNode]) -> Int {
        Int(data.reduce(0) { partialResult, node in partialResult + node.count })
    }
    
//    period is measured in days
//    This is purely convenience
    private func getRecentData(from data: [DataNode], in period: Double = 7) -> [DataNode] {
        data.filter { node in node.date >= .now.resetToStartOfDay() - (period * Constants.DayTime) }
    }
    
    private func updatePeriod(from data: [DataNode]) -> [DataNode] {
        if viewFilter == 0 { return getRecentData(from: data) }
        else { return data }
    }
    
//    This determines whether its showing all time or just this week
    @State var viewFilter: Int = 0
    
    var body: some View {
        
//        These are typically used for the charts
        let hourlyData = makeData { event in event.getLengthInHours() }
//        in general the compressed data is used for data sumarries, that dont need every individaul node
        let compressedHourlyData = compressData(from: hourlyData)
        
        let tagData = makeData { _ in 1 }
        let compressedTagData = compressData(from: tagData)
        
        let totalHours = getTotalHours(from: hourlyData)
        
        DataCollection("Events") {
            
            Group {
                Seperator(orientation: .horizontal)
                EventsDataSummaries.LargeText(mainText: "\(totalHours)", subText: "hours")
                Seperator(orientation: .horizontal)
                EventsDataSummaries.LargeText(mainText: "\(hourlyData.count)", subText: "events")
                Seperator(orientation: .horizontal)
            }
            
            DataPicker(optionsCount: 2, labels: ["This Week", "All Time"], fontSize: Constants.UISubHeaderTextSize, selectedOption: $viewFilter)
                .padding(.bottom)
            
            Group {
                UniversalText("Daily Averages", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                    .padding(.bottom, 5)
                
                AverageActivityByTag(data: updatePeriod(from: hourlyData), unit: "")
                Seperator(orientation: .horizontal)
                EventsDataSummaries.LargeText(mainText: "\((Double(totalHours) / Double(hourlyData.count)).round(to: 2))", subText: "HR/DY")
                    .padding(.vertical)
                EventsDataSummaries.DailyAverage(data: updatePeriod(from: compressedHourlyData), unit: "HR/DY")
            }
            
            Seperator(orientation: .horizontal)
            
            Group {
                UniversalText("Activities", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                
                ActivitiesPerDay("Hours per day, by tag", data: updatePeriod(from: hourlyData), scrollable: viewFilter == 1 )
                    .frame(height: 200)
                EventsDataSummaries.SuperlativeEvents(data: updatePeriod(from: compressedHourlyData), unit: "HR")
                EventsDataSummaries.ActivityPerTag(data: updatePeriod(from: compressedHourlyData), unit: "HR")
                
                Seperator(orientation: .horizontal)
                
                ActivitiesPerDay("Events per day, by tag", data: updatePeriod(from: tagData), scrollable: viewFilter == 1 )
                    .frame(height: 200)
                EventsDataSummaries.SuperlativeEvents(data: updatePeriod(from: compressedTagData), unit: "")
                EventsDataSummaries.ActivityPerTag(data: updatePeriod(from: compressedTagData), unit: "")
                
                Seperator(orientation: .horizontal)
            }
            
        }.id( DataPageView.DataBookMark.Events.rawValue )
        
        
    }
    
}
