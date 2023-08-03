//
//  Charts.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI
import Charts

//MARK: Scroll Chart
struct ScrollChart<Content: View>: View {
    
    let content: Content
    
    init( @ViewBuilder _ content: () -> Content ) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal) {
                content
                    .frame(width: geo.size.width)
            }
        }
    }
}

//MARK: ActivitesPerDay
struct ActivitiesPerDay: View {
    
    private func makeData() -> [DataNode] {
        events.compactMap { event in
            DataNode(date: event.startTime, count: dataAggregator(event), category: event.getTagLabel(), goal: "")
        }.sorted { node1, node2 in node1.category < node2.category }
    }
    
    
    let title: String
    let events: [RecallCalendarEvent]
    
//    This is how you will count individual events (ie. what is their contribution to their tag?)
//    For hourly, this is how many hours it is, weighted adds the goal multiplier, and events simply counts 1 for each event
    let dataAggregator: (RecallCalendarEvent) -> Double
    
    init( _ title: String, with events: [RecallCalendarEvent], aggregator: @escaping (RecallCalendarEvent) -> Double ) {
        
        self.title = title
        self.events = events
        self.dataAggregator = aggregator
    
    }
    
//    MARK: Charts
    
    @ViewBuilder
    private func makeChart(from data: [DataNode]) -> some View {
        Chart {
            ForEach(data) { datum in
                BarMark(x: .value("date", datum.date, unit: .day ),
                        y: .value("count", datum.count))
                .foregroundStyle(by: .value("series", datum.category))
                .cornerRadius(Constants.UIDefaultCornerRadius - 10)
            }
        }
        .colorChartByTag()
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as( Date.self ) {
                    AxisValueLabel(centered: true) {
                        UniversalText(date.formatted(.dateTime.day() ), size: Constants.UISmallTextSize, font: Constants.mainFont)
                        
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let count = value.as(Int.self) {
                    AxisValueLabel {
                        UniversalText("\(count)", size: Constants.UISmallTextSize, font: Constants.mainFont)
                    }
                }
            }
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        let data = makeData()
        let recentData = data.filter { node in node.date >= .now.resetToStartOfDay() - (7 * Constants.DayTime) }
        
        let _ = print(recentData.count)
        
        VStack(alignment: .leading) {
            UniversalText(title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                .padding(.bottom)
            
            
            UniversalText("This week", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            makeChart(from: recentData)
                .secondaryOpaqueRectangularBackground()
                .frame(height: 200)
            
            ActivityHoursPerDaySummary(data: recentData, fullBreakdown: false)
                .padding(.bottom)
            
        
            UniversalText("All time", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            ScrollChart {
                makeChart(from: data)
            }
            .secondaryOpaqueRectangularBackground()
            .frame(height: 200)
            
            ActivityHoursPerDaySummary(data: data, fullBreakdown: true)
                .padding(.bottom)
            
        }
    }
}
