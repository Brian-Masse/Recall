//
//  CalendarPage.swift
//  Recall
//
//  Created by Brian Masse on 8/6/24.
//

import Foundation
import SwiftUI

struct CalendarPage: View {
    
    private struct LocalConstants {
        static let gridSpacing: Double = 10
        static let daysPerRow: Double = 7
    }
    
    private func getStartOfMonth(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: date)))!
    }
    
    private func getStartOfMonthOfffset(for date: Date) -> Int {
        let startOfMonth = getStartOfMonth(for: date)
        return Calendar.current.component(.weekday, from: startOfMonth) - 1
    }
    
    private func gridItemWidth(in geo: GeometryProxy) -> Double {
        let space = (LocalConstants.gridSpacing * (LocalConstants.daysPerRow - 1))
        return (geo.size.width - space) / ( LocalConstants.daysPerRow )
    }
    
    @ViewBuilder
    private func makeMonth(_ date: Date, in geo: GeometryProxy) -> some View {
        let dayCount = Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
        let startOfMonthOffset = getStartOfMonthOfffset(for: date)
        
        let width = gridItemWidth(in: geo)
        
        VStack {
            
            Text("\(date.formatted(date: .complete, time: .omitted))")
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: width, maximum: width),
                                         spacing: LocalConstants.gridSpacing,
                                         alignment: .bottom)],
                      alignment: .leading,
                      spacing: 5) {
                
                ForEach(-startOfMonthOffset..<Int(dayCount), id: \.self) { i in
                    makeDay(for: Double(i + 1))
                        .frame(height: width)
                }
                
            }
        }
    }
    
    @ViewBuilder
    private func makeDay(for day: Double) -> some View {
        ZStack {
            Rectangle()

            Text("\(Int(day))")

                .foregroundStyle(.blue)
        }
    }
    
    @State private var currentMonth: Date = .now
    
    @State private var upperBound: Int = 10
    
    var body: some View {
        
        VStack {
            
            Text("upperBound: \(upperBound)")
            
            GeometryReader { geo in
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        
                        LazyVStack {
                            
                            ForEach( 0..<upperBound, id: \.self ) { i in
                                let date = Calendar.current.date(byAdding: .month, value: -i, to: currentMonth)!
                                
                                makeMonth(date, in: geo)
                                    .id(i)
                                    .rotationEffect(Angle(degrees: 180)).scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                                    .onAppear {
                                        
                                        if i > upperBound - 5 {
                                            upperBound += 10
                                        } else if i < upperBound - 15 {
                                            upperBound -= 10
                                        }
                                    }
                            }
                        }
                    }
                    .rotationEffect(Angle(degrees: 180)).scaleEffect(x: -1.0, y: 1.0, anchor: .center)
                    .onAppear { proxy.scrollTo(0, anchor: .top) }
                }
            }
        }
    }
}

#Preview {
    CalendarPage()
}
