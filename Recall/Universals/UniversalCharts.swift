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
                .padding(.trailing)
        }
//        }
    }
}


//MARK: Goals Over Time Chart
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

struct ChartOverTimeXAxis: ViewModifier {
    func body(content: Content) -> some View {
        content
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as( Date.self ) {
                        
                        let dateLabel = "\(date.formatted(.dateTime.day()))"
                        
                        let sundayLabel = !date.isSunday() ? "" : "Sun"
                        let bottomLabel = date.isFirstOfMonth() ? "\(date.formatted(.dateTime.month()))" : ( sundayLabel )
                        
                        AxisValueLabel(centered: true) {
                            VStack(alignment: .leading) {
                                UniversalText( dateLabel, size: Constants.UISmallTextSize, font: Constants.mainFont, wrap: false)
                                UniversalText(bottomLabel, size: Constants.UISmallTextSize, font: Constants.mainFont)
                            }
                        }
                    }
                }
            }
    }
}

struct ReversedXAxis: ViewModifier {
    func body(content: Content) -> some View {
        content
            .chartXScale(domain: .automatic(includesZero: true, reversed: true  ))
    }
}


//MARK: ColoringCharts
private struct ColorChartByTag: ViewModifier {
    
    @ObservedResults(RecallCategory.self) var tags
    @State var dictionary: Dictionary<String, Color> = Dictionary()
    
    func body(content: Content) -> some View {
        
        content
            .chartForegroundStyleScale { value in dictionary[value] ?? .red }
            .onAppear {
                var dic: Dictionary<String, Color> = Dictionary()
                if tags.count == 0 { return }
                dic["?"] = .white
                for i in 0..<tags.count  {
                    let key: String =  tags[i].label
                    dic[key] = tags[i].getColor()
                }
                self.dictionary = dic
            }
    }
}

private struct ColorChartByGoal: ViewModifier {
    
    @ObservedResults(RecallGoal.self) var goals
    @State var dictionary: Dictionary<String, Color> = Dictionary()
    
    func body(content: Content) -> some View {
        
        content
            .chartForegroundStyleScale { value in dictionary[value] ?? .red }
            .onAppear {
                var dic: Dictionary<String, Color> = Dictionary()
                if goals.count == 0 { return }
                dic["?"] = .white
                for i in 0..<goals.count  {
                    let key: String =  goals[i].label
                    dic[key] = Colors.colorOptions[min( Colors.colorOptions.count - 1, i)]
                }
                self.dictionary = dic
            }
    }
}

private struct ColorChartByList: ViewModifier {
    
    @ObservedResults(RecallGoal.self) var goals
    @State var dictionary: Dictionary<String, Color>
    
    func body(content: Content) -> some View {
        
        content
            .chartForegroundStyleScale { value in dictionary[value] ?? .red }
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
    
    func colorChartByList(_ dictionary: Dictionary<String, Color>) -> some View {
        modifier(ColorChartByList(dictionary: dictionary))
    }
}

