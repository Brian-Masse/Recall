//
//  CalendarPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals
import UniversalDonationPackage

struct CalendarPageView: View {
    
//    MARK: Convenience Functions
    private func setCurrentDay(with date: Date) {
        if date > viewModel.currentDay { slideDirection = .right }
        else { slideDirection = .left }
        
        withAnimation { viewModel.setCurrentDay(to: date) }
    }
    
//   MARK: vars
    let events: [RecallCalendarEvent]
    let goals: [RecallGoal]
    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: RecallCalendarViewModel = RecallCalendarViewModel.shared
    
    @State var showingCreateEventView: Bool = false
    @State var showingProfileView: Bool = false
    @State var showingDonationView: Bool = false
    @State var showingCalendarView: Bool = false
    
    @State var slideDirection: AnyTransition.SlideDirection = .right
    
    @Namespace private var calendarPageViewNameSpace
    
    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday().month().day())
    }
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeDateLabel() -> some View {
        let matches = viewModel.currentDay.matches(.now, to: .day)
        
        HStack {
            let currentLabel    = formatDate(viewModel.currentDay)
            let nowLabel        = formatDate(.now)
            
            if !matches {
                UniversalText(currentLabel, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                Image(systemName: "arrow.forward")
                    .opacity(0.8)
            }
            
            UniversalText(nowLabel, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                .onTapGesture { setCurrentDay(with: .now) }
        }
    }
    
//    MARK: DateSelector
    @ViewBuilder
    private func makeDateSelector(from date: Date) -> some View {
        
        let dayString = date.formatted(.dateTime.day(.twoDigits))
        let monthString = date.formatted(.dateTime.month(.abbreviated)).lowercased()
        let isCurrentDay = date.matches(viewModel.currentDay, to: .day)
    
        VStack {
            UniversalText(dayString,
                          size: Constants.UIDefaultTextSize,
                          font: Constants.titleFont,
                          wrap: false, scale: true)
            .opacity(isCurrentDay ? 1 : 0.75)
            
            if isCurrentDay {
                UniversalText(monthString,
                              size: Constants.UIDefaultTextSize,
                              font: Constants.titleFont,
                              wrap: false, scale: true )
            }
        }
        .padding(.vertical)
        .padding(.horizontal, isCurrentDay ? 15 : 5)
        .background {
            if isCurrentDay {
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                    .matchedGeometryEffect(id: "currentDaySelector", in: calendarPageViewNameSpace)
                    .universalStyledBackgrond(.secondary, onForeground: true)
            }
        }
        .onTapGesture { setCurrentDay(with: date) }
    }

    
    @ViewBuilder
    private func makeDateSelectors() -> some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: 0) {
                    
                    let dayCount = RecallModel.index.daysSinceFirstEvent()
                    
                    ForEach(0..<dayCount, id: \.self) { i in
                        let date: Date = (Date.now) - (Double(i) * Constants.DayTime)
                        makeDateSelector(from: date)
                            .id(i)
                    }
                }
                .frame(height: 75)
                .onChange(of: viewModel.currentDay) {
                    let proposedIndex = floor(Date.now.timeIntervalSince(viewModel.currentDay) / Constants.DayTime)
                    reader.scrollTo(Int(proposedIndex))
                }
            }
        }
    }
    
//    MARK: Headers
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            UniversalText( "Recall",
                           size: Constants.UIHeaderTextSize,
                           font: Constants.titleFont,
                           wrap: false, scale: true )
            Spacer()
            
            
            ResizableIcon("calendar", size: Constants.UIDefaultTextSize)
                .rectangularBackground(style: .secondary)
                .padding(.leading)
                .onTapGesture { showingCalendarView = true }
            
            ResizableIcon("person", size: Constants.UIDefaultTextSize)
                .rectangularBackground(style: .secondary)
                .onTapGesture { showingProfileView = true }
        }
        
        
//        makeDateLabel()
    }
    
//    MARK: DateTape
    @ViewBuilder
    private func makeDateTape(on day: Date) -> some View {
        let calendar = Calendar(identifier: .gregorian)
        
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: day)
        let week = calendar.date(from: comps) ?? day + Constants.WeekTime
        
        let dayFormat = Date.FormatStyle().day(.twoDigits)
        let dayOfWeekFormat = Date.FormatStyle().weekday(.narrow)
        
        HStack {
            ForEach( 0..<7, id: \.self) { i in
                let day = calendar.date(byAdding: .day, value: 6 - i, to: week)!
                let isCurrentDay = day.matches(viewModel.currentDay, to: .day)
                
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        UniversalText( day.formatted(dayOfWeekFormat), size: Constants.UISmallTextSize, font: Constants.mainFont )
                            .opacity(0.75)
                            .padding(.bottom, -5)
                        
                        UniversalText( day.formatted(dayFormat), size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                    }
                    .opacity( i == 0 || i == 6 ? 0.5 : 1 )
                    .foregroundStyle( isCurrentDay ? .black :  ( colorScheme == .dark ? .white : .black ) )
                    .background { if isCurrentDay  {
                        Circle()
                            .frame(width: 50, height: 50)
                            .universalStyledBackgrond(.accent, onForeground: true)
                    } }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture { setCurrentDay(with: day) }
            }
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack() {
            VStack(alignment: .leading) {
                makeHeader()
                    .padding(.horizontal, 7)

//                makeDateSelectors()
                makeDateTape(on: viewModel.currentDay)
                    .padding(.vertical)
            }
            
            CalendarContainer(events: Array(events))
        }
        .padding(7)
        .sheet(isPresented: $showingCreateEventView) {
            CalendarEventCreationView.makeEventCreationView(currentDay: viewModel.currentDay)
        }
        .sheet(isPresented: $showingProfileView) {
            ProfileView()
        }
        .sheet(isPresented: $showingCalendarView) {
            CalendarPage()
        }
        .universalBackground()
        
    }
}


//    MARK: File level extensions
//    swiftUI does not, in any convenient capacity allow you to write code conditional to software version
//    the easiest (most possible) solution is to just have a bunch of extensions and only apply them to the views you need
extension View {
    @ViewBuilder
    func makeDateSelectorsHStackSnapping() -> some View {
        if #available(iOS 17, *) {
            self.scrollTargetLayout()
        } else { self }
    }
    
    @ViewBuilder
    func makeDateSlectorsScrollViewSnapping() -> some View {
        if #available(iOS 17, *) {
            self.scrollTargetBehavior(.viewAligned)
        } else { self }
    }
}
