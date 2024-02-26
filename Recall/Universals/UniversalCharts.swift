//
//  Chart Universals.swift
//  Recall
//
//  Created by Brian Masse on 8/15/23.
//

import Foundation
import SwiftUI
import Charts
import RealmSwift
import UIUniversals

//This file contains charts and chart elements used throughout the app to make them more consistent and easily edited.

//MARK: Scroll Chart
//The scrollView makes a chart with lots of datalayed out horizontall scroll.
//Not all charts use this Wrapper, some use a custom one to lazily load their data
struct ScrollChart<Content: View>: View {
    
    let dataCount: Int
    let content: Content
    
    init( _ dataCount: Int, @ViewBuilder _ content: () -> Content ) {
        self.dataCount = max(dataCount, 21)
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            content
                .frame(width: Double(dataCount) * 16 )
                .padding(.trailing)
        }
    }
}


//MARK: Goals Over Time Chart
//Any chart that lays out its goals over time should use this modifier. It makes it so there is a standardized axis for users
struct GoalsOverTimeChart: ViewModifier {
    let unit: String
    
    func body(content: Content) -> some View {
        content
            .chartOverTimeXAxis()
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
            .padding(.top, 5)
    }
}

//MARK: ChartOverTimeXAxis
//any chart that lays time out along the xAxis should use this viewModifer. It makes it so there is a standardized axis for users
struct ChartOverTimeXAxis: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .chartXAxis {
                let baseColor: Color = colorScheme == .dark ? .white : .black
                let lighterColor = baseColor.opacity(0.5)

                AxisMarks(preset: .extended, values: .stride(by: .day)) { value in
                    if let date = value.as( Date.self ) {
                        let dateLabel = "\(date.formatted(.dateTime.day(.twoDigits)))"

                        let sundayLabel = !date.isSunday() ? "" : "Sun"
                        let bottomLabel = date.isFirstOfMonth() ? "\(date.formatted(.dateTime.month()))" : ( sundayLabel )
                        
                        AxisValueLabel(centered: true) {
                            UniversalText("\( dateLabel)\n\(bottomLabel)", size: Constants.UISmallTextSize, textAlignment: .center)
                        }.foregroundStyle(bottomLabel != "" ? baseColor : lighterColor)

                    }
                }
            }
    }
}

//MARK: ReversedXAxis
//this puts the most recent dates at the front
struct ReversedXAxis: ViewModifier {
    func body(content: Content) -> some View {
        content
            .chartXScale(domain: .automatic(includesZero: true, reversed: true  ))
    }
}


//MARK: ColoringCharts
private struct ColorChartByTag: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .chartForegroundStyleScale { value in Constants.tagColorsDic[value] ?? .red }
    }
}

private struct ColorChartByGoal: ViewModifier {
    func body(content: Content) -> some View {
        content
            .chartForegroundStyleScale { value in Constants.goalColorsDic[value] ?? .red }
    }
}

//MARK: View Extension
extension View {
    func goalsOverTimeChart(unit: String = "") -> some View {
        modifier(GoalsOverTimeChart(unit: unit))
    }
    
    func chartOverTimeXAxis() -> some View {
        modifier( ChartOverTimeXAxis() )
    }
    
    func reversedXAxis() -> some View {
        modifier( ReversedXAxis() )
    }
    
    func colorChartByTag() -> some View {
        modifier(ColorChartByTag())
    }
    
    func colorChartByGoal() -> some View {
        modifier(ColorChartByGoal())
    }
}

//MARK: CircularProgressBar
struct CircularProgressView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let currentValue: Double
    let totalValue: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    colorScheme == .dark ? .black : Colors.baseLight,
                    lineWidth: Constants.UICircularProgressWidth
                )
            Circle()
                .trim(from: 0, to: CGFloat(currentValue / totalValue) )
                .stroke(
                    Colors.getAccent(from: colorScheme),
                    style: StrokeStyle(
                        lineWidth: Constants.UICircularProgressWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
            
            VStack {
                UniversalText("\(Int(currentValue)) / \(Int(totalValue))", size: Constants.UIHeaderTextSize, font: Constants.titleFont, wrap: false, scale: true)
                    .padding(.bottom, 5)
                UniversalText("\(((currentValue / totalValue) * 100).round(to: 2)  )%", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            }.padding()
        }
    }
}
