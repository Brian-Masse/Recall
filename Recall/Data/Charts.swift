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
import UIUniversals

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
    
    @ObservedResults(RecallCategory.self,
                     where: { tag in tag.ownerID == RecallModel.ownerID }) var tags
    
    let recents: Bool
    let data: [DataNode]
    let unit: String
    
    @State var activeLabel: String? = nil
    
    var body: some View {
        
        let averageData = transformData()
        let max = transformData().first?.count ?? 1.5
        
        UniversalText( "Average Activity, HR/DY", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            Chart {
                ForEach(averageData) { datum in
                    BarMark(x: .value("X", datum.category),
                            y: .value("Y", datum.count  ))
                    
                    .foregroundStyle(by: .value("SERIES", datum.category))
                    .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                    
                }
                
                if let label = activeLabel {
                    RuleMark(x: .value("X", label))
                        .annotation(position: .overlay ) {
                            UniversalText( label, size: Constants.UIDefaultTextSize, font: Constants.mainFont, wrap: false )
                                .frame(minWidth: 150)
                                .rectangularBackground(style: .secondary)
                        }
                        .foregroundStyle( Constants.tagColorsDic[ label ] ?? .red )
                }
            }
            .chartYScale(domain: 0...max )
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
                            Text(count.convertToString())
                                .font(.caption2)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [1, 2] ) )
                    }
                }
            }
            .frame(height: 130)
            .rectangularBackground(style: .transparent, stroke: true)
    }
}

//MARK: ActivitesPerDay
struct ActivitiesPerDay: View {
    
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    @ViewBuilder
    private func makeChart() -> some View {
        
        Chart {
            ForEach(0...getMaxIndex(), id: \.self) { i in
                let datum = data[i]
                
                BarMark(x: .value("X", datum.date, unit: .day ),
                        y: .value("Y", datum.count),
                        width: 12)
                .foregroundStyle(by: .value("series", datum.category))
                .cornerRadius(Constants.UIBarMarkCOrnerRadius)
            }
        }
        .chartLegend(.hidden)
        .frame(height: 230)
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
                            coordinator.goTo(.calendar)
                            currentDay = date
                        }
                        
                    })
            }
        }
    }
    
    @State private var showingFullLegend: Bool = false
    
    @ViewBuilder
    private func makeLegend() -> some View {
        let rowCount: Double = 4
        let tags: [RecallCategory] = RealmManager.retrieveObjectsInList()
        let itemsPerRow: Int = Int(ceil(Double(tags.count) / rowCount))
        
        HStack {
            UniversalText( "Legend", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            Spacer()
        }
        
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                
                ForEach( 0..<Int(rowCount), id: \.self ) { f in
                 
                    HStack(spacing: 7) {
                        ForEach( 0..<itemsPerRow, id: \.self ) { i in
                            let index = i + ( itemsPerRow * f )
                            if index < tags.count {
                                let tag = tags[index]
                                
                                Circle()
                                    .foregroundStyle(tag.getColor())
                                    .frame(width: 10, height: 10)
                                
                                UniversalText(tag.label, size: Constants.UISmallTextSize, font: Constants.mainFont)
                                    .opacity(0.75)
                                    .padding(.trailing)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getMaxIndex() -> Int { min( data.count - 1, loadedDataCount ) }
    private func daysSinceLastEvent() -> Int {
        Int( Date.now.timeIntervalSince(data[getMaxIndex()].date) / Constants.DayTime)
    }
    
//    this controls how much data will be rendered onAppear
    static let initialLoadedDataCount: Int = 250
    
    let title: String
    let data: [DataNode]
    let scrollable: Bool
    
    @Binding var currentDay: Date
    
    @State var loadedDataCount: Int = initialLoadedDataCount
    
    init( _ title: String, data: [DataNode], scrollable: Bool = false, currentDay: Binding<Date>) {
        self.title = title
        self.data = data
        self.scrollable = scrollable
        self._currentDay = currentDay
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                UniversalText(title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                
                Spacer()
                
                HStack {
                    UniversalText( "load more", size: Constants.UISmallTextSize, font: Constants.mainFont )
                    RecallIcon("arrow.down.to.line")
                }
                .padding(5)
                .onTapGesture { withAnimation {
                    loadedDataCount += ActivitiesPerDay.initialLoadedDataCount
                } }
            }
            
            VStack {
                if getMaxIndex() > 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        makeChart()
                            .frame(width: Double(daysSinceLastEvent()) * 16 )
                            .padding(.trailing)
                    }
                }
                
                makeLegend()
            }
            .rectangularBackground(style: .transparent, stroke: true)
        }
    }
}


//MARK: Goals Charts



//MARK: GoalCompletionOverTime
struct GoalCompletionOverTime: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    static let initialLoadedDataCount: Int = 50
    
    let data: [DataNode]
    let unit: String
    
    @State var loadedDataCount: Int = initialLoadedDataCount

    private func getMaxIndex() -> Int { min(loadedDataCount, data.count - 1) }
    private func daysSinceLastEvent() -> Int {
        Int(Date.now.timeIntervalSince(data[getMaxIndex()].date) / Constants.DayTime)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                UniversalText("Goals completion over time", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                
                Spacer()
                
                HStack {
                    UniversalText( "load more", size: Constants.UISmallTextSize, font: Constants.mainFont )
                    RecallIcon("arrow.down.to.line")
                }
                .padding(5)
                .onTapGesture { withAnimation {
                    loadedDataCount += ActivitiesPerDay.initialLoadedDataCount
                } }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Chart {
                    ForEach(0...getMaxIndex(), id: \.self) { i in
                        let datum = data[i]
                        
                        LineMark(x: .value("date", datum.date, unit: .day ),
                                 y: .value("count", datum.count))
                        .interpolationMethod(.cardinal)
                        .foregroundStyle(Colors.getAccent(from: colorScheme))
                        AreaMark(x: .value("date", datum.date, unit: .day ),
                                 y: .value("count", datum.count))
                        .interpolationMethod(.cardinal)
                        .foregroundStyle( LinearGradient(colors: [Colors.getAccent(from: colorScheme).opacity(0.5), .clear], startPoint: .top, endPoint: .bottom ) )
                    }
                }
                .frame(width: Double(daysSinceLastEvent()) * 16 )
                .goalsOverTimeChart(unit: unit)
                .reversedXAxis()
                .colorChartByGoal()
            }.rectangularBackground(style: .transparent, stroke: true)
        }
    }
    
}

//MARK: Goal Progress over time
struct GoalProgressOverTime: View {
    
    let title: String
    let data: [DataNode]
    let unit: String
    
    
//    this controls how much data will be rendered onAppear
    static let initialLoadedDataCount: Int = 75
    @State var loadedDataCount: Int = initialLoadedDataCount
    
    var maxIndex: Int { max(0, min( data.count - 1, loadedDataCount )) }
    var daysSinceLastEvent: Int {
        Int(Date.now.timeIntervalSince( data[maxIndex].date ) / Constants.DayTime)
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                UniversalText(title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                
                Spacer()
                
                HStack {
                    UniversalText( "load more", size: Constants.UISmallTextSize, font: Constants.mainFont )
                    RecallIcon("arrow.down.to.line")
                }
                .padding(5)
                .onTapGesture { withAnimation {
                    loadedDataCount += GoalProgressOverTime.initialLoadedDataCount
                } }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                Chart {
                    ForEach(0...maxIndex, id: \.self) { i in
                        
                        let datum = data[i]
                        
                        BarMark(x: .value("X", datum.date, unit: .day),
                                y: .value("Y", datum.count),
                                width: .automatic)
                        .foregroundStyle(by: .value("Series", datum.goal))
                        .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                    }
                }
                .frame(width: Double(daysSinceLastEvent) * 16 )
                .chartYAxis(.hidden)
                .reversedXAxis()
                .colorChartByGoal()
                .goalsOverTimeChart(unit: unit)
            }.rectangularBackground(style: .transparent, stroke: true)
        }
    }
}

//MARK: Goal Averages
struct GoalAverages: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    private enum Page: String, Identifiable {
        case all
        case average
        
        var id: String { self.rawValue }
    }

    @MainActor
    @ViewBuilder
    private func makeChart( makeYData: @escaping (DataNode) -> Double) -> some View {
        Chart {
            ForEach(data) { datum in
                if datum.category == "completed" {
                    BarMark(x: .value("X", datum.goal),
                            y: .value("Y", makeYData(datum)))
                    .foregroundStyle(Colors.getAccent(from: colorScheme))
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
        .frame(height: 150)
    }
    
    let title: String
    let data: [DataNode]
    let unit: String
    
    @State private var page: Page = .all
    
    var body: some View {
        VStack(alignment: .leading) {
            
            let chartTitle = page == .all ? title : "Average \(title)"
            
            UniversalText(chartTitle, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
            
            TabView(selection: $page) {
                makeChart { node in node.count }.tag(Page.all)
                makeChart { node in node.count / node.getDaysSinceGoalCreation() }.tag(Page.average)
            }
            .tabViewStyle(.page)
            .frame(height: 150)
            .rectangularBackground(style: .transparent, stroke: true)
        }
    }
}

//MARK: GoalsMetPercentageChart
struct GoalsMetPercentageChart: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let title: String
    let data: [DataNode]
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading) {
            
            UniversalText(title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
            
            Chart {
                ForEach(data) { datum in
                    BarMark(x: .value("X", datum.goal),
                            y: .value("Y", datum.count))
                    .cornerRadius(Constants.UIBarMarkCOrnerRadius)
                    .foregroundStyle(Colors.getAccent(from: colorScheme))
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
            .frame(height: 160)
            .colorChartByGoal()
            .rectangularBackground(style: .transparent, stroke: true)
        }
    }
}
