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

//MARK: CalendarPageDateTape
private struct CalendarPageDateTape: View {
    
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var viewModel = RecallCalendarContainerViewModel.shared
    
    var body: some View {
        let calendar = Calendar(identifier: .gregorian)
        
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: viewModel.currentDay )
        let week = calendar.date(from: comps) ?? viewModel.currentDay + Constants.WeekTime
        
        let dayFormat = Date.FormatStyle().day(.twoDigits)
        let dayOfWeekFormat = Date.FormatStyle().weekday(.narrow)
        
        HStack {
            ForEach( 0..<7, id: \.self) { i in
                let day = calendar.date(byAdding: .day, value: i, to: week)!
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
                .onTapGesture { viewModel.setCurrentDay(to: day) }
            }
        }
    }
}

//MARK: CalendarPageToolBar
private struct CalendarPageToolBar: View {
    
    @ObservedObject private var viewModel = RecallCalendarContainerViewModel.shared
    
//    MARK: ToolBar
    @State private var showingToolBar: Bool = false
    @State private var toggledToolBarInGesture: Bool = false
    
    @ViewBuilder
    private func makeCalendarLayoutButton(icon: String, count: Int, activeValue: Int, action: @escaping (Int) -> Void) -> some View {
        let isCurrent = activeValue == count
        
        RecallIcon(icon)
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
                makeCalendarLayoutButton(icon: "rectangle", count: 1, activeValue: viewModel.daysPerView)           { count in RecallModel.index.setCalendarColoumnCount(to: count)}
                makeCalendarLayoutButton(icon: "rectangle.split.2x1", count: 2, activeValue: viewModel.daysPerView) { count in RecallModel.index.setCalendarColoumnCount(to: count)}
                makeCalendarLayoutButton(icon: "rectangle.split.3x1", count: 3, activeValue: viewModel.daysPerView) { count in RecallModel.index.setCalendarColoumnCount(to: count)}
            }
            
            HStack(spacing: 0) {
                Spacer()
                
                let density = viewModel.getDensity()
                
                makeCalendarLayoutButton(icon: "widget.medium", count: 0, activeValue: density)       { count in RecallModel.index.setCalendarDensity(to: count) }
                makeCalendarLayoutButton(icon: "widget.large", count: 1, activeValue: density)        { count in RecallModel.index.setCalendarDensity(to: count) }
                makeCalendarLayoutButton(icon: "widget.extralarge", count: 2, activeValue: density)   { count in RecallModel.index.setCalendarDensity(to: count) }
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
                CalendarPageDateTape()
                    .frame(height: 50)
                    .transition(
                        .modifier(active: ToolBarTransition(offset: 50), identity: ToolBarTransition(offset: 0))
                        .combined(with: .opacity)
                    )
            }
//
            HStack {
                Spacer()
                
                RecallIcon(showingToolBar ? "chevron.up" : "chevron.down")
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
    
    
    var body: some View {
        makeToolRibbon()
            .gesture(toolBarGesture)
    }
    
}

//MARK: CalendarPageView
struct CalendarPageView: View {
    
    //   MARK: vars
    let events: [RecallCalendarEvent]
    let goals: [RecallGoal]
    let dailySummaries: [RecallDailySummary]
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let viewModel: RecallCalendarContainerViewModel = RecallCalendarContainerViewModel.shared
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    @Namespace private var calendarPageViewNameSpace
    
    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.weekday().month().day())
    }
    
//    MARK: Headers
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            UniversalButton {
                UniversalText( "Recall",
                               size: Constants.UIHeaderTextSize,
                               font: Constants.titleFont,
                               wrap: false, scale: true )
            } action: { viewModel.setCurrentDay(to: .now) }

            Spacer()
            
            RecallIcon("calendar")
                .rectangularBackground(style: .secondary)
            
                .safeZoomMatch(id: RecallnavigationMatchKeys.monthlyCalendarView, namespace: calendarPageViewNameSpace)
                .onTapGesture { coordinator.push(.monthlyCalendarView(namespace: calendarPageViewNameSpace)) }
            
            RecallIcon("person")
                .rectangularBackground(style: .secondary)
                .safeZoomMatch(id: RecallnavigationMatchKeys.profileView, namespace: calendarPageViewNameSpace)
                .onTapGesture { coordinator.push(.profileView(namespace: calendarPageViewNameSpace)) }
        }
    }
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            makeHeader()
                .padding(.horizontal, 7)
            
            CalendarPageToolBar()
                
            
            CalendarContainer(events: Array(events), summaries: dailySummaries)
                .onAppear {
                    print(events.count)
                }
        }
        .padding(7)
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


