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
    static let sharedContainerModel = CalendarContainerModel()
    
    let events: [RecallCalendarEvent]
    let goals: [RecallGoal]
    
    @ObservedObject var containerModel: CalendarContainerModel = sharedContainerModel
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
                          font: isCurrentDay ? Constants.titleFont : Constants.mainFont,
                          wrap: false, scale: true)
            
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
                    
                    ForEach(0..<100) { i in
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
        
        makeDateLabel()
    }
    
    
//    MARK: Body
    
    var body: some View {
        
        ZStack(alignment: .top) {
            TestingCalendarContainer(events: Array(events))
            
            VStack(alignment: .leading, spacing: 5) {
                makeHeader()
                
                HStack {
                    makeDateSelectors()
                    
                    LargeRoundedButton("recall", icon: "arrow.up") { showingCreateEventView = true }
                }
            }
            .padding([.bottom, .horizontal])
            .background {
                RoundedRectangle(cornerRadius: Constants.UILargeCornerRadius)
                    .ignoresSafeArea()
                    .foregroundStyle(.thinMaterial)
            }
        }
//        .padding(7)
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
