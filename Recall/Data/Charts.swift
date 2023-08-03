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

//MARK: AverageActivityByTag
struct AverageActivityByTag: View {
    
    @MainActor
    private func transformData() -> [DataNode] {
        let timePeriod = Date.now.timeIntervalSince( RecallModel.index.earliestEventDate ) / Constants.DayTime
        return data.compactMap { node in
            .init(date: .now, count: node.count / timePeriod, category: node.category, goal: "")
        }
        
    }
    
    let data: [DataNode]
    let unit: String
    
    var body: some View {
        
        let averageData = transformData()
        
        UniversalText( "Average Activity HR/DY", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        Chart {
            ForEach(averageData) { datum in
                BarMark(x: .value("X", datum.category),
                        y: .value("Y", datum.count  ))
                .foregroundStyle(by: .value("SERIES", datum.category))
                .cornerRadius(Constants.UIBarMarkCOrnerRadius)

            }
        }
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let count = value.as(Double.self) {
                    AxisValueLabel {
                        UniversalText("\(count.round(to: 2)) " + unit, size: Constants.UISmallTextSize, font: Constants.mainFont)
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [1, 2] ) )
                }
            }
        }
        .secondaryOpaqueRectangularBackground()
        .padding(.bottom)
    }
}

//MARK: ActivitesPerDay
struct ActivitiesPerDay: View {
    
    @ViewBuilder
    private func makeChart() -> some View {
        Chart {
            ForEach(data) { datum in
                BarMark(x: .value("date", datum.date, unit: .day ),
                        y: .value("count", datum.count))
                .foregroundStyle(by: .value("series", datum.category))
                .cornerRadius(Constants.UIBarMarkCOrnerRadius)
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
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [1, 2] ) )
                }
            }
        }
    }
    
    let title: String
    let data: [DataNode]
    let scrollable: Bool
    
    init( _ title: String, data: [DataNode], scrollable: Bool = false ) {
        self.title = title
        self.data = data
        self.scrollable = scrollable
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
                
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Group {
                if scrollable {
                    ScrollChart {
                        makeChart()
                    }
                }else {
                    makeChart()
                }
            }
            .secondaryOpaqueRectangularBackground()
            .padding(.bottom)
        }
    }
}
