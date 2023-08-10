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
    
    let dataCount: Int
    let content: Content
    
    init( _ dataCount: Int, @ViewBuilder _ content: () -> Content ) {
        self.dataCount = dataCount
        self.content = content()
    }
    
    var body: some View {
//        GeometryReader { geo in
        ScrollView(.horizontal) {
            content
                .frame(width: Double(dataCount) * Constants.UIScrollableBarWidthDouble )
        }
//        }
    }
}

//MARK: Event Charts



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
        .colorChartByTag()
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
//        .secondaryOpaqueRectangularBackground()
    }
}

//MARK: ActivitesPerDay
struct ActivitiesPerDay: View {
    
    @ViewBuilder
    private func makeChart() -> some View {
        Chart {
            ForEach(data) { datum in
                
                BarMark(x: .value("X", datum.date, unit: .day ),
                        y: .value("Y", datum.count),
                        width: scrollable ? Constants.UIScrollableBarWidth : .automatic)
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
                    ScrollChart(data.count) {
                        makeChart()
                    }
                }else {
                    makeChart()
                }
            }
            .padding(.bottom)
        }
    }
}


//MARK: Goals Charts

struct GoalsOverTimeChart: ViewModifier {
    
    let unit: String
    
    func body(content: Content) -> some View {
        content
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as( Date.self ) {
                        let label = date.isFirstOfMonth() ? "01\n\(date.formatted(.dateTime.month()))" : "\(date.formatted(.dateTime.day()))"
                        
                        AxisValueLabel(centered: true) {
                            UniversalText( label, size: Constants.UISmallTextSize, font: Constants.mainFont)
                            
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            UniversalText("\(count)" + unit, size: Constants.UISmallTextSize, font: Constants.mainFont)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [1, 2] ) )
                    }
                }
            }
    }
}

extension View {
    func goalsOverTimeChart(unit: String = "") -> some View {
        modifier(GoalsOverTimeChart(unit: unit))
    }
}



//MARK: GoalCompletionOverTime
struct GoalCompletionOverTime: View {
    
    let data: [DataNode]
    let unit: String
    
    
    var body: some View {
        
        VStack(alignment: .leading) {
            UniversalText("Goals met per day", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            ScrollChart(data.count) {
                Chart {
                    ForEach(data) { datum in
                        LineMark(x: .value("date", datum.date, unit: .day ),
                                 y: .value("count", datum.count))
                        .interpolationMethod(.cardinal)
                        .foregroundStyle(Colors.tint)
                        
                        AreaMark(x: .value("date", datum.date, unit: .day ),
                                 y: .value("count", datum.count))
                        .interpolationMethod(.cardinal)
                        .foregroundStyle( LinearGradient(colors: [Colors.tint.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom ) )
                    }
                }
                .goalsOverTimeChart(unit: unit)
            }
        }
    }
    
}

//MARK: Goal Progress over time

struct GoalProgressOverTime: View {
    
    let data: [DataNode]
    let unit: String
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText("goal progress over time", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Chart {
                ForEach(data) { datum in
                    
                    BarMark(x: .value("X", datum.date),
                            y: .value("Y", datum.count))
                    .foregroundStyle(by: .value("Series", datum.goal))
                }
            }
            .colorChartByTag()
            .goalsOverTimeChart(unit: unit)
        }
    }
}

//MARK: Goal Averages

struct GoalAverages: View {
    
    let data: [DataNode]
    let unit: String
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText("Average Goal Progress", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Chart {
                ForEach(data) { datum in
                    BarMark(x: .value("X", datum.goal),
                            y: .value("Y", datum.count))
                    .foregroundStyle(Colors.tint)
                }
            }
        }
    }
}
