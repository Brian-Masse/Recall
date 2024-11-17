//
//  MonthlyCalendarView.swift
//  Recall
//
//  Created by Brian Masse on 8/6/24.
//

import Foundation
import SwiftUI
import UIUniversals
import RealmSwift

struct MonthlyCalendarView: View {
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
    @ObservedObject var calendarViewModel = RecallCalendarContainerViewModel.shared
    
    @ObservedResults(RecallCalendarEvent.self) var events
    
    private var arrEvents: [RecallCalendarEvent] { Array(events) }
    
//    MARK: Convenience Functions
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
        return (geo.size.width - LocalConstants.strokePadding - space) / ( LocalConstants.daysPerRow )
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
    private func makeMonth(_ date: Date, in width: CGFloat) -> some View {
        
        let dayCount = Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
        let startOfMonthOffset = getStartOfMonthOfffset(for: date)
        let startOfMonth = getStartOfMonth(for: date)
        
        VStack(alignment: .leading, spacing: 0) {
            UniversalText( getMonthName(for: date),
                           size: Constants.UISubHeaderTextSize,
                           font: Constants.titleFont)
            .padding(.vertical, 10)
            .padding(.top)
  
            VStack {
                
                let rowCount = Int(ceil(Double( dayCount + startOfMonthOffset  ) / 7))
                
                ForEach( 0..<rowCount, id: \.self ) { i in
                    
                    HStack(spacing: 0) {
                        HStack(spacing: LocalConstants.gridSpacing ) {
                            ForEach( 0..<7, id: \.self ) { f in
                                let day = (i * 7) + f - startOfMonthOffset
                                
                                if day <= -1 {Rectangle() .foregroundStyle(.clear)
                                } else if day < dayCount {
                                    DayView(day: day, startOfMonth: startOfMonth, width: width)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: Constants.UILargeCornerRadius))
                        
                        Spacer()
                    }
                    
                    if i < rowCount - 1 { Divider() }
                }
            }
            .rectangularBackground(LocalConstants.strokePadding, style: .secondary, stroke: true)
        }
    }
    
//    MARK: DayView
    private struct DayView: View {
        
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.dismiss) var dismiss
        
        private let viewModel = CalendarPageViewModel.shared
        private let calendarViewModel = RecallCalendarContainerViewModel.shared
        
        @State private var date: Date = .now
        @State private var recallWasCompleted: Bool = false
        @State private var roundRightEdge: Bool = false
        
        let day: Int
        let startOfMonth: Date
        let width: Double
        
        private func getDate() async -> Date { startOfMonth + (Constants.DayTime * Double(day)) }
        
        private func checkCompletion() async -> Bool { viewModel.recallWasCompleted(on: date) }
        
        private func shouldRoundRightEdge() async -> Bool {
            let previousDay = Calendar.current.date(byAdding: .day, value: 1, to: self.date)!
            return !viewModel.recallWasCompleted(on: previousDay )
        }
        
        var  body: some View {
            
            UniversalText("\(Int(day + 1))",
                          size: Constants.UISubHeaderTextSize,
                          font: Constants.titleFont)
            
                .frame(width: width, height: width)
                .opacity( date > .now || !recallWasCompleted ? 0.15 : 1 )
                .foregroundStyle( recallWasCompleted ? .black : Colors.getBase(from: colorScheme, reversed: true) )
                .background { if recallWasCompleted {
                        Rectangle()
                            .foregroundStyle(Colors.getAccent(from: colorScheme))
                            .cornerRadius(100, corners: [.topLeft, .bottomLeft])
                            .cornerRadius(roundRightEdge ? 100 : 0, corners: [.topRight, .bottomRight] )
                            .padding(.trailing, roundRightEdge ? 0 : -30)
                            .transition(.blurReplace)
                } }
                .task {
                    self.date                   = await getDate()
                    self.roundRightEdge         = await shouldRoundRightEdge()
                    let recallWasCompleted      = await checkCompletion()
                    
                    withAnimation { self.recallWasCompleted = recallWasCompleted }
                }
            
                .onTapGesture {
                    calendarViewModel.setCurrentDay(to: date)
                    dismiss()
                }
            
        }
    }
    
//    MARK: Calendar
    @State private var offset: CGFloat = 0
    
    @MainActor
    @ViewBuilder
    private func makeCalendar() -> some View {
        GeometryReader { geo in
            let width = gridItemWidth(in: geo)
            
            InfiniteScroller { i in
                let month = Calendar.current.date(byAdding: .month, value: i, to: .now)!
                
                makeMonth(month, in: width)
            }
        }
    }
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            VStack(alignment: .leading) {
                UniversalText("Calendar",
                              size: Constants.UIHeaderTextSize,
                              font: Constants.titleFont)
                
                UniversalText("\(Date.now.formatted(date: .complete, time: .omitted))",
                              size: Constants.UIDefaultTextSize,
                              font: Constants.mainFont)
            }
            
            Spacer()
            
            DismissButton()
        }
    }
    
//    MARK: makeDaysOfWeekHeader
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
        .onAppear {
            viewModel.renderCalendar(events: arrEvents)
            
        }
        .padding(7)
        .universalBackground()
    }
}

#Preview {
    
    MonthlyCalendarView()
    
}
