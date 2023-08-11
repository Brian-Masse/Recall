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
                
            let days = RecallModel.getDaysSinceFirstEvent()
            
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Group {
                if scrollable {
                    ScrollChart(Int(days)) {
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



//MARK: Goals Over Time Chart
struct GoalsOverTimeChart: ViewModifier {
    
    let unit: String
    
    func body(content: Content) -> some View {
        content
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as( Date.self ) {
                        
                        let regularLabel = !date.isSunday() ? "\(date.formatted(.dateTime.day()))" : "\(date.formatted(.dateTime.day()))\nSun"
                        let label = date.isFirstOfMonth() ? "01\n\(date.formatted(.dateTime.month()))" : regularLabel
                        
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
            .padding(.top, 5)
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
                .colorChartByGoal()
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
            
            let days = RecallModel.getDaysSinceFirstEvent()
            
            UniversalText("goal progress over time", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            ScrollChart(Int(days)) {
                Chart {
                    ForEach(data) { datum in
                        
                        BarMark(x: .value("X", datum.date),
                                y: .value("Y", datum.count),
                                width: Constants.UIScrollableBarWidth)
                        .foregroundStyle(by: .value("Series", datum.goal))
                        .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                    }
                }
                .colorChartByGoal()
                .goalsOverTimeChart(unit: unit)
            }
        }
    }
}

//MARK: Goal Averages

struct GoalAverages: View {
    
    private enum Page: String, Identifiable {
        case all
        case average
        
        var id: String { self.rawValue }
    }
    
    @ViewBuilder
    private func makeChart( makeYData: @escaping (DataNode) -> Double) -> some View {

        Chart {
            ForEach(data) { datum in
                BarMark(x: .value("X", datum.goal),
                        y: .value("Y", makeYData(datum)))
                .foregroundStyle(by: .value("Series", datum.goal))
                .cornerRadius(Constants.UIBarMarkCOrnerRadius)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let count = value.as(Double.self) {
                    AxisValueLabel {
                        UniversalText("\(count.round(to: 2))" + unit, size: Constants.UISmallTextSize, font: Constants.mainFont)
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [1, 2] ) )
                }
            }
        }
        .frame(height: 150)
        .colorChartByGoal()
        .padding(.top, 5)
    }
    
    let title: String
    let data: [DataNode]
    let unit: String
    
    @State private var page: Page = .all
    
    var body: some View {
        
        let totalDay = RecallModel.getDaysSinceFirstEvent()
        
        VStack(alignment: .leading) {
            
            
            let chartTitle = page == .all ? title : "Average \(title)"
            
            UniversalText(chartTitle, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            TabView(selection: $page) {
                makeChart { node in node.count }.tag(Page.all)
                makeChart { node in node.count / totalDay }.tag(Page.average)
            }
            .tabViewStyle(.page)
            .frame(height: 150)
        }
    }
}

//MARK: GoalsMetPercentageChart
struct GoalsMetPercentageChart: View {
    
    let title: String
    let data: [DataNode]
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading) {
            
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Chart {
                ForEach(data) { datum in
                    BarMark(x: .value("X", datum.goal),
                            y: .value("Y", datum.count))
                    .foregroundStyle(by: .value("Series", datum.goal))
                    .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    if let count = value.as(Double.self) {
                        AxisValueLabel {
                            UniversalText("\(count.round(to: 2))" + unit, size: Constants.UISmallTextSize, font: Constants.mainFont)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [1, 2] ) )
                    }
                }
            }
            .frame(height: 150)
            .colorChartByGoal()
        }
    }
}
