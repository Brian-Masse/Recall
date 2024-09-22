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
//                            .padding(.bottom, -5)
                        
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
    
//    MARK: ToolBar
    @State private var showingToolBar: Bool = false
    @State private var toggledToolBarInGesture: Bool = false
    
    @ViewBuilder
    private func makeCalendarLayoutButton(icon: String, count: Int, activeValue: Int, action: @escaping (Int) -> Void) -> some View {
        let isCurrent = activeValue == count
        
        Image(systemName: icon)
            .padding(.horizontal, isCurrent ? 15 : 7)
            .padding(.vertical)
            .contentShape(Rectangle())
            .background { if isCurrent {
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                    .universalStyledBackgrond(.secondary, onForeground: true)
            } }
            .onTapGesture { withAnimation { action(count) }}
    }
   
    
    @ViewBuilder
    private func makeToolBar() -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                makeCalendarLayoutButton(icon: "rectangle", count: 1, activeValue: viewModel.daysPerView)           { count in viewModel.setDaysPerView(to: count)}
                makeCalendarLayoutButton(icon: "rectangle.split.2x1", count: 2, activeValue: viewModel.daysPerView) { count in viewModel.setDaysPerView(to: count)}
                makeCalendarLayoutButton(icon: "rectangle.split.3x1", count: 3, activeValue: viewModel.daysPerView) { count in viewModel.setDaysPerView(to: count)}
            }
            
            HStack(spacing: 0) {
                Spacer()
                
                let density = viewModel.getDensity()
                
                makeCalendarLayoutButton(icon: "widget.medium", count: 0, activeValue: density)       { count in viewModel.getScale(from: count) }
                makeCalendarLayoutButton(icon: "widget.large", count: 1, activeValue: density)        { count in viewModel.getScale(from: count) }
                makeCalendarLayoutButton(icon: "widget.extralarge", count: 2, activeValue: density)   { count in viewModel.getScale(from: count) }
            }
        }
    }
    
//    MARK: ToolRibbon
    @ViewBuilder
    private func makeToolRibbon() -> some View {
        VStack(spacing: 0) {
            if showingToolBar {
                makeToolBar()
                    .frame(height: 50)
                    .transition(
                        .modifier(active: ToolBarTransition(offset: 50), identity: ToolBarTransition(offset: 0))
                        .combined(with: .opacity)
                    )
            } else {
                makeDateTape(on: viewModel.currentDay)
                    .frame(height: 50)
                    .transition(
                        .modifier(active: ToolBarTransition(offset: 50), identity: ToolBarTransition(offset: 0))
                        .combined(with: .opacity)
                    )
            }
//            
            HStack {
                Spacer()
                
                Image(systemName: showingToolBar ? "chevron.up" : "chevron.down")
                    .padding(.vertical, 5)
                    .opacity(0.65)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { showingToolBar.toggle() } }
        }.contentShape(Rectangle())
    }
    
//    MARK: ToolBarTransition
    private struct ToolBarTransition: ViewModifier, Animatable {
        let offset: Double

        func body(content: Content) -> some View {
            content
                .offset(y: -offset)
                .blur(radius: abs(offset) / 10)
        }
    }
    
//    MARK: Toolbar Gesture
    private var toolBarGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if !toggledToolBarInGesture && abs(value.translation.height) > 25 {
                    withAnimation { showingToolBar.toggle() }
                    self.toggledToolBarInGesture = true
                }
            }
            .onEnded { _ in self.toggledToolBarInGesture = false }
    }
    
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            makeHeader()
                .padding(.horizontal, 7)
            
            makeToolRibbon()
                .gesture(toolBarGesture)
            
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


