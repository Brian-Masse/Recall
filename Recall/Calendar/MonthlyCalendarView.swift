//
//  CalendarPage.swift
//  Recall
//
//  Created by Brian Masse on 8/6/24.
//

import Foundation
import SwiftUI
import UIUniversals
import RealmSwift

//MARK: CalendarPageViewModel
class CalendarPageViewModel: ObservableObject {
    
    static let shared: CalendarPageViewModel = CalendarPageViewModel()
    
    var recallLog: [String: Bool] = [:]
    private var renderedMonths: [String: Bool] = [:]
    
    static func makeMonthKey(from date: Date) -> String {
        let style = Date.FormatStyle().month().year()
        return date.formatted(style)
    }
    
    
    private func getStartOfMonth(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: date)))!
    }
    
    func recallWasCompleted(on date: Date) -> Bool {
        (RecallModel.index.eventsIndex[date.getDayKey()] ?? 0) != 0
    }
}

struct CalendarPage: View {
//    MARK: LocalConstants
    private struct LocalConstants {
        static let gridSpacing: Double = 5
        static let daysPerRow: Double = 7
        static let strokePadding: Double = 10
    }
    
//    MARK: Vars
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var viewModel = CalendarPageViewModel.shared
    @ObservedObject var calendarViewModel = RecallCalendarViewModel.shared
    
//    @State private var currentMonth: Date = .now
//    @State private var upperBound: Int = 10
    
    @ObservedResults(RecallCalendarEvent.self) var events
    
    private var arrEvents: [RecallCalendarEvent] { Array(events) }
    
//    MARK: Convenience Functions
    @MainActor
    
    
    private func getDay(of date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }
    
    private func getStartOfMonth(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: date)))!
    }
    
    private func getStartOfMonthOfffset(for date: Date) -> Int {
        let startOfMonth = getStartOfMonth(for: date)
        return Calendar.current.component(.weekday, from: startOfMonth) - 1
    }
    
    private func gridItemWidth(in geo: GeometryProxy) -> Double {
        let space = (LocalConstants.gridSpacing * (LocalConstants.daysPerRow - 1)) + (LocalConstants.strokePadding * 2) + 1
        return (geo.size.width - space) / ( LocalConstants.daysPerRow )
    }
    
    private func getMonthName(for date: Date) -> String {
        let format = Date.FormatStyle().month().year()
        return date.formatted(format)
    }

    private func getDayOfWeekTitle(_ day: Int) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let days = calendar.weekdaySymbols
        
        return days[day]
    }
    
//    MARK: MonthView
    @MainActor
    @ViewBuilder
    private func makeMonth(_ date: Date, in geo: GeometryProxy) -> some View {
        let dayCount = Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
        let startOfMonthOffset = getStartOfMonthOfffset(for: date)
        let startOfMonth = getStartOfMonth(for: date)
        
        let width = gridItemWidth(in: geo)
        
        VStack(alignment: .leading, spacing: 0) {
//
            
            
            UniversalText( getMonthName(for: date),
                           size: Constants.UISubHeaderTextSize,
                           font: Constants.titleFont)
            .padding(.vertical, 10)
            .padding(.top)
  
            ZStack {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: width, maximum: width),
                                             spacing: LocalConstants.gridSpacing,
                                             alignment: .bottom)],
                          alignment: .leading,
                          spacing: LocalConstants.gridSpacing) {
                    
                    ForEach(-startOfMonthOffset..<Int(dayCount), id: \.self) { i in
                        let day = Calendar.current.date(byAdding: .day, value: i, to: startOfMonth) ?? .now
                    
                        let roundLeftEdge = shouldRoundLeftEdgeOfDay(day, startOfMonthOffset: startOfMonthOffset)
                        let roundRightEdge = shouldRoundRightEdgeOfDay(day, startOfMonthOffset: startOfMonthOffset, monthCount: dayCount)
                        
                        VStack {
                            if i >= 0 {
                                makeDay(for: day, roundLeftEdge: roundLeftEdge, roundRightEdge: roundRightEdge)
                            } else {
                                Rectangle().foregroundStyle(.clear)
                            }
                        }
                        .frame(height: width * 1.25)
                    }
                }
                
                VStack {
                    let dividerCount = ceil(Double( dayCount + startOfMonthOffset  ) / 7)
                    
                    ForEach( 0..<Int(dividerCount), id: \.self ) { i in
                        Spacer()
                        Divider()
                            .opacity(i == Int(dividerCount - 1) ? 0 : 1)
                    }
                }
                
            }
            .rectangularBackground(LocalConstants.strokePadding, style: .secondary, stroke: true)
        }
    }
    
//    MARK: DayView
    private func shouldRoundLeftEdgeOfDay(_ day: Date, startOfMonthOffset: Int) -> Bool {
        let dayCount = getDay(of: day)
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        
        if dayCount == 1 { return true }
        if !viewModel.recallWasCompleted(on: previousDay ) { return true }
        
        return (dayCount + startOfMonthOffset - 1) % 7 == 0
    }
    
    private func shouldRoundRightEdgeOfDay(_ day: Date, startOfMonthOffset: Int, monthCount: Int) -> Bool {
        let dayCount = getDay(of: day)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        
        if dayCount == monthCount { return true }
        if !viewModel.recallWasCompleted(on: nextDay ) { return true }
        
        return (dayCount + startOfMonthOffset) % 7 == 0
    }
    
    @MainActor
    @ViewBuilder
    private func makeDay(for day: Date, roundLeftEdge: Bool, roundRightEdge: Bool) -> some View {
//        let isCurrentDay = day.matches(.now, to: .day)
        let dayNumber: Int = getDay(of: day)
        let recallWasCompleted: Bool = viewModel.recallWasCompleted(on: day)
//        Int.random(in: 0...1) == 1
        
        VStack(spacing: 0 ) {
            HStack { Spacer() }
            
            Spacer()
            
            UniversalText("\(Int(dayNumber))",
                          size: Constants.UISubHeaderTextSize,
                          font: Constants.titleFont)
            
            Spacer()
        }
        .opacity( day > .now || !recallWasCompleted ? 0.15 : 1 )
        .if(recallWasCompleted) { view in view.foregroundStyle(.black) }
        .background {
            
            if recallWasCompleted {
                Rectangle()
                    .foregroundStyle(Colors.getAccent(from: colorScheme))
                    .cornerRadius(roundLeftEdge ? 100 : 0, corners: [.topLeft, .bottomLeft] )
                    .cornerRadius(roundRightEdge ? 100 : 0, corners: [.topRight, .bottomRight] )
                    .padding(.vertical, 5)
                    .padding(.horizontal, -5)
            }
            
        }
        .onTapGesture {
            calendarViewModel.setCurrentDay(to: day)
            dismiss()
        }
    }
    
//    MARK: Calendar
    
    @State private var offset: CGFloat = 0
    
    @MainActor
    @ViewBuilder
    private func makeCalendar() -> some View {
        
        GeometryReader { geo in
            InfiniteScroller { i in
                let month = Calendar.current.date(byAdding: .month, value: i, to: .now)!
                
                makeMonth(month, in: geo)
            }
        }
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeHeader() -> some View {
        VStack(alignment: .leading) {
            UniversalText("Calendar",
                          size: Constants.UIHeaderTextSize,
                          font: Constants.titleFont)
            
            UniversalText("\(Date.now.formatted(date: .complete, time: .omitted))",
                          size: Constants.UIDefaultTextSize,
                          font: Constants.mainFont)
        }
    }
    
    @ViewBuilder
    private func makeDaysOfWeekHeader() -> some View {
        HStack(alignment: .center, spacing: 0 ) {
            ForEach( 0..<7, id: \.self ) { i in

                Spacer()
                
                UniversalText( "\( getDayOfWeekTitle(i) )",
                               size: Constants.UIDefaultTextSize,
                               font: Constants.mainFont)
                
                Spacer()
                
                if i != 6 {
                    Divider(vertical: true, strokeWidth: 1)
                        .frame(maxHeight: 20)
                        .opacity(0.5)
                }
            }
        }.opacity(0.5)
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            
            makeHeader()
                .padding(.bottom)
            
            makeDaysOfWeekHeader()
                .padding(.bottom, 5)
            
            makeCalendar()
        }
        .padding(7)
        .universalBackground()
    }
}
