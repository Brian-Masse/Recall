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
}

