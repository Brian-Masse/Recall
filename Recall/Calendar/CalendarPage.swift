//
//  CalendarPage.swift
//  Recall
//
//  Created by Brian Masse on 8/6/24.
//

import Foundation
import SwiftUI
import UIUniversals

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
    
    private func recallWasCompleted(on date: Date, in events: [RecallCalendarEvent]) -> Bool {
        events.filter { event in event.startTime.matches(date, to: .day) }
            .count > 0
    }
    
    func renderMonth(_ month: Date) {
        if self.renderedMonths[ CalendarPageViewModel.makeMonthKey(from: month) ] ?? false { return }
        
        let dayCount = Calendar.current.range(of: .day, in: .month, for: month)?.count ?? 0
        let startOfMonth = getStartOfMonth(for: month)
        let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth)!
        
        let events = RecallModel.realmManager.realm.objects(RecallCalendarEvent.self).filter { event in
            event.startTime > startOfMonth && event.startTime < endOfMonth
        }
        let arrEvents = Array(events)
        
        for i in 0..<dayCount {
            let day = Calendar.current.date(byAdding: .day, value: i, to: startOfMonth)!
            let recallWasCompleted = recallWasCompleted(on: day, in: arrEvents)
            
            self.recallLog[ day.formatted(date: .numeric, time: .omitted) ] = recallWasCompleted
        }
        
        self.renderedMonths[ CalendarPageViewModel.makeMonthKey(from: month) ] = true
        self.objectWillChange.send()
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
    
    @ObservedObject var viewModel = CalendarPageViewModel.shared
    
    @State private var currentMonth: Date = .now
    @State private var upperBound: Int = 10
    
    @Binding var currentDay: Date
    
    let goals: [RecallGoal]
    
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
                        
                        VStack {
                            if i >= 0 {
                                makeDay(for: day)
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
            .rectangularBackground(LocalConstants.strokePadding, style: .secondary)
        }
    }
    
//    MARK: DayView
    @MainActor
    @ViewBuilder
    private func makeDay(for day: Date) -> some View {
        let isCurrentDay = day.matches(.now, to: .day)
        let dayNumber: Int = getDay(of: day)
        
        let recallWasCompleted: Bool = viewModel.recallLog[ day.formatted(date: .numeric, time: .omitted) ] ?? false
        
        VStack(spacing: 0 ) {
            HStack { Spacer() }
            
            Spacer()
            
            if recallWasCompleted {
                Circle()
                    .universalStyledBackgrond(.accent, onForeground: true)
                    .frame(width: 7, height: 7)
            }
            
            UniversalText("\(Int(dayNumber))",
                          size: Constants.UISubHeaderTextSize,
                          font: Constants.titleFont)
            .padding(.top, 7)
            
            Spacer()
        }
        .opacity( day > .now || !recallWasCompleted ? 0.15 : 1 )
        .if(isCurrentDay) { view in view.universalStyledBackgrond(.accent, onForeground: true) }
        .onTapGesture {
            currentDay = day
            dismiss()
        }
    }
    
//    MARK: Calendar
    @MainActor
    @ViewBuilder
    private func makeCalendar() -> some View {
        GeometryReader { geo in
            
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    
                    LazyVStack {
                        
                        ForEach( 0..<upperBound, id: \.self ) { i in
                            let date = Calendar.current.date(byAdding: .month, value: -i, to: currentMonth)!
                            
                            makeMonth(date, in: geo)
                                .id(i)
                                .onAppear {
                                    
                                    viewModel.renderMonth(date)
                                    
                                    if i > upperBound - 5 {
                                        upperBound += 10
                                    } else if i < upperBound - 15 {
                                        upperBound -= 10
                                    }
                                }
                        }
                    }
                }
                .onAppear { proxy.scrollTo(0, anchor: .top) }
                .clipShape(RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius))
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
                .padding(.bottom, 30)
        }
        .padding()
        .universalBackground()
    }
}

struct TestView: View {
    
    @State private var day: Date = .now
    
    var body: some View {
        CalendarPage(currentDay: $day, goals: [])
    }
    
}

#Preview(body: {
    TestView()
})
