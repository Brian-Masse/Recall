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
        static let gridSpacing: Double = 3
        static let daysPerRow: Double = 7
        static let strokePadding: Double = 15
    }
    
//    MARK: Line
    struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            return path
        }
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
    
    private func getStartOfMonthOfffset(for date: Date) -> Int {
        let startOfMonth = date.getStartOfMonth()
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
        
        let dayCount = date.getDaysInMonth()
        let startOfMonthOffset = getStartOfMonthOfffset(for: date)
        let startOfMonth = date.getStartOfMonth()
        
        VStack(alignment: .leading, spacing: 0) {
            UniversalText( getMonthName(for: date),
                           size: Constants.UISubHeaderTextSize,
                           font: Constants.titleFont)
            .padding(.top)
            
            Line()
                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 7]))
                .frame(height: 1)
                .padding(.vertical)
                .opacity(0.25)
  
            VStack(alignment: .leading, spacing: LocalConstants.gridSpacing ) {
                
                let rowCount = Int(ceil(Double( dayCount + startOfMonthOffset  ) / 7))
                
                ForEach( 0..<rowCount, id: \.self ) { i in
                    HStack(spacing: LocalConstants.gridSpacing ) {
                        ForEach( 0..<7, id: \.self ) { f in
                            let day = (i * 7) + f - startOfMonthOffset
                            
                            if day <= -1 {Rectangle().foregroundStyle(.clear).frame(width: width)
                            } else if day < dayCount {
                                DayView(day: day, startOfMonth: startOfMonth, width: width)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UILargeCornerRadius))
                }
            }
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
        @State private var eventCount: Int = 0
        @State private var roundRightEdge: Bool = false
        
        let day: Int
        let startOfMonth: Date
        let width: Double
        
        private func getDate() async -> Date { startOfMonth + (Constants.DayTime * Double(day)) }
        
        private func checkCompletion() async -> Bool {
            self.eventCount = viewModel.recallWasCompleted(on: date)
            return eventCount > 0
        }
        
        private func shouldRoundRightEdge() async -> Bool {
            let previousDay = Calendar.current.date(byAdding: .day, value: 1, to: self.date)!
            return viewModel.recallWasCompleted(on: previousDay ) == 0
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
                            .cornerRadius(Constants.UIDefaultCornerRadius - 13)
                            .transition(.blurReplace)
                            .opacity( Double(eventCount) / 11 )
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
    private func makeCalendar(itemWidth: Double) -> some View {
        InfiniteScroller { i in
            let month = Calendar.current.date(byAdding: .month, value: i, to: .now)!
            makeMonth(month, in: itemWidth)
        }
        .padding(LocalConstants.strokePadding)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: Constants.UIDefaultCornerRadius,
                                          bottomLeadingRadius: Constants.UILargeCornerRadius,
                                          bottomTrailingRadius: Constants.UILargeCornerRadius,
                                          topTrailingRadius: Constants.UIDefaultCornerRadius))
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Constants.UIDefaultCornerRadius,
                                   bottomLeadingRadius: Constants.UILargeCornerRadius,
                                   bottomTrailingRadius: Constants.UILargeCornerRadius,
                                   topTrailingRadius: Constants.UIDefaultCornerRadius)
            .universalStyledBackgrond(.secondary, onForeground: true)
            
            UnevenRoundedRectangle(topLeadingRadius: Constants.UIDefaultCornerRadius,
                                   bottomLeadingRadius: Constants.UILargeCornerRadius,
                                   bottomTrailingRadius: Constants.UILargeCornerRadius,
                                   topTrailingRadius: Constants.UIDefaultCornerRadius)
            .stroke(lineWidth: 1)
        }
        
//        .rectangularBackground(LocalConstants.strokePadding, style: .secondary, stroke: true, cornerRadius: Constants.UILargeCornerRadius)
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
    private func makeDaysOfWeekHeader(itemWidth: Double) -> some View {
        HStack(alignment: .center, spacing: 0 ) {
            ForEach( 0..<7, id: \.self ) { i in
                UniversalText( "\( getDayOfWeekTitle(i) )", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                    .frame(width: max(itemWidth, 1) + LocalConstants.gridSpacing)
                
                if i != 6 {
                    Divider(vertical: true, strokeWidth: 1)
                        .frame(maxHeight: 20)
                        .opacity(0.5)
                }
            }
        }
        .opacity(0.5)
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            let width = gridItemWidth(in: geo)
            
            VStack(alignment: .leading, spacing: 5) {
                
                makeHeader()
                    .padding(.bottom)
                
                VStack(spacing: 5) {
                    makeDaysOfWeekHeader(itemWidth: width)
                        .padding(.bottom, 5)
                    
                    makeCalendar(itemWidth: width)
                }
            }
        }
        .task { await viewModel.renderCalendar(events: arrEvents) }
        .padding(7)
        .universalBackground()
    }
}

//#Preview {
//    MonthlyCalendarView()
//}
