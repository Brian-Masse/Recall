//
//  Charts.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI
import Charts
import RealmSwift


//MARK: Event Charts



//MARK: AverageActivityByTag
struct AverageActivityByTag: View {
    
    @MainActor
    private func transformData() -> [DataNode] {
        let timePeriod = recents ? 7 : Date.now.timeIntervalSince( RecallModel.index.earliestEventDate ) / Constants.DayTime
        return data.compactMap { node in
            .init(date: .now, count: node.count / timePeriod, category: node.category, goal: "")
        }.sorted { node1, node2 in
            node1.count >= node2.count
        }
    }
    
    private func findMax(from data: [DataNode]) -> Double {
        let maxLabel = data.first?.category ?? "?"
        return data.reduce(0) { partialResult, node in
            if node.category == maxLabel {
                return partialResult + node.count
            }
            return partialResult
        }
        
    }
    
    @ObservedResults(RecallCategory.self) var tags
    
    let recents: Bool
    let data: [DataNode]
    let unit: String
    
    @State var activeLabel: String? = nil
    
    var body: some View {
        
        let averageData = transformData()
        let max = findMax(from: averageData)
        
        UniversalText( "Average Activity HR/DY", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
//        ScrollView(.horizontal) {
            Chart {
                ForEach(averageData) { datum in
                    BarMark(x: .value("X", datum.category),
                            y: .value("Y", datum.count  ))
                    
                    .foregroundStyle(by: .value("SERIES", datum.category))
                    .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                    
                }
                
                if let label = activeLabel {
                    RuleMark(x: .value("X", label))
                        .annotation(position: .top) {
                            UniversalText( label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                                .secondaryOpaqueRectangularBackground()
                        }
                        .foregroundStyle( Constants.tagColorsDic[ label ] ?? Colors.tint )
                }
            }
            .chartYScale(domain: 0...(CGFloat(max) + ( recents ? 2 : 1 )))
            .chartXAxis( tags.count >= 10 ? .hidden : .visible)
            .chartOverlay { proxy in
                GeometryReader { innerProxy in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged{ value in
                                    if let tag: String = proxy.value(atX: value.location.x - 30) {
                                        activeLabel = tag
                                    }
                                }
                                .onEnded { value in
                                    activeLabel = nil
                                }
                        )
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
//            .chartXAxis {
//                AxisMarks { value in
//                    AxisValueLabel(orientation: .vertical)
//                }
//            }
//            .frame(width: 20 * CGFloat(tags.count))
//        }
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
                        width: .automatic)
                .foregroundStyle(by: .value("series", datum.category))
                .cornerRadius(Constants.UIBarMarkCOrnerRadius)
            }
        }
        .reversedXAxis()
        .chartOverTimeXAxis()
        .colorChartByTag()
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
        .chartOverlay() { proxy in
            GeometryReader { innerProxy in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: { point in
                        if let date: Date = proxy.value(atX: point.x) {
                            page = .calendar
                            currentDay = date
                        }
                        
                    })
//                    .gesture(
//                        DragGesture()
//                            .onChanged{ value in
//                                if let tag: String = proxy.value(atX: value.location.x - 30) {
//                                    activeLabel = tag
//                                }
//                            }
//                            .onEnded { value in
//                                activeLabel = nil
//                            }
//                    )
            }
        }
        .frame(height: 220)
    }
    
    let title: String
    let data: [DataNode]
    let scrollable: Bool
    
    @Binding var page: MainView.MainPage
    @Binding var currentDay: Date
    
    init( _ title: String, data: [DataNode], scrollable: Bool = false, page: Binding<MainView.MainPage>, currentDay: Binding<Date>) {
        self.title = title
        self.data = data
        self.scrollable = scrollable
        self._page = page
        self._currentDay = currentDay
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
                .padding(.top)
                .goalsOverTimeChart(unit: unit)
                .reversedXAxis()
                .colorChartByGoal()
            }
        }
    }
    
}

//MARK: Goal Progress over time

struct GoalProgressOverTime: View {
    
    let title: String
    let data: [DataNode]
    let unit: String
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            let days = RecallModel.getDaysSinceFirstEvent()
            
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            ScrollChart(Int(days)) {
                
                Chart {
                    ForEach(data) { datum in
                        
                        BarMark(x: .value("X", datum.date, unit: .day),
                                y: .value("Y", datum.count),
                                width: .automatic)
                        .foregroundStyle(by: .value("Series", datum.goal))
                        .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                    }
                }
                .reversedXAxis()
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
    
    @Environment(\.colorScheme) var colorScheme
    
    @MainActor
    @ViewBuilder
    private func makeChart( makeYData: @escaping (DataNode) -> Double) -> some View {

//        in the future, this should also include the 'uncompleted' counts too
        Chart {
            ForEach(data) { datum in
                if datum.category == "completed" {
                    
                    BarMark(x: .value("X", datum.goal),
                            y: .value("Y", makeYData(datum)))
                    .foregroundStyle(by: .value("Series", datum.category))
                    .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                    
                    .annotation(position: .top, alignment: .top) { context in
                        if datum.category == "completed" {
                            let label = page == .all ? "\(Int(makeYData(datum)))" : "\(makeYData(datum).round(to: 2))"
                            UniversalText(label, size: Constants.UISmallTextSize, font: Constants.mainFont)
                                .zIndex(1000)
                        }
                    }
                }
            }
        }
        .chartLegend(Visibility.hidden)
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
        .colorChartByList([
            "completed": Colors.tint,
            "uncompleted": (colorScheme == .dark ? Colors.darkGrey : Colors.secondaryLightColor)
        ])
        .frame(height: 150)
        .padding(.top, 5)
    }
    
    let title: String
    let data: [DataNode]
    let unit: String
    
    @State private var page: Page = .all
    
    var body: some View {
        VStack(alignment: .leading) {
            
            let chartTitle = page == .all ? title : "Average \(title)"
            
            UniversalText(chartTitle, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            TabView(selection: $page) {
                makeChart { node in node.count }.tag(Page.all)
                makeChart { node in node.count / node.getDaysSinceGoalCreation() }.tag(Page.average)
            }
            #if os(iOS)
            .tabViewStyle(.page)
            #endif
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
                    .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                    .foregroundStyle(Colors.tint)
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
