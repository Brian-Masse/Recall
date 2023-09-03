//
//  CalendarPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct CalendarPageView: View {
    
//    MARK: Convenience Functions
    
    private func setCurrentDay(with date: Date) {
        if date > currentDay { swipeDirection = .right }
        else { swipeDirection = .left }
        
        withAnimation { currentDay = date }
    }
    
//   MARK: vars

    let events: [RecallCalendarEvent]
    
    @State var showingCreateEventView: Bool = false
    @State var currentDay: Date = .now
    @State var swipeDirection: AnyTransition.SlideDirection = .right

    @State var showingProfileView: Bool = false
    @Binding var appPage: ContentView.EntryPage
    
    @Namespace private var calendarPageView
    
    private func formatDate(_ date: Date) -> String {
        let weekDay = date.formatted(.dateTime.weekday())
        let month = date.formatted(.dateTime.month(.abbreviated))
        let day = date.formatted(.dateTime.day())
        return "\(weekDay), \(month) \(day)"
    }
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeDateLabel() -> some View {
        let matches = currentDay.matches(.now, to: .day)
        
        HStack {
            let currentLabel    = formatDate(currentDay)
            let nowLabel        = formatDate(.now)
            
            if !matches {
                UniversalText(currentLabel, size: Constants.UIDefaultTextSize, font: Constants.mainFont, lighter: true)
                Image(systemName: "arrow.forward")
                    .opacity(0.8)
            }
            
            UniversalText(nowLabel, size: Constants.UIDefaultTextSize, font: Constants.mainFont, lighter: true )
                .onTapGesture { setCurrentDay(with: .now) }
        }
        .padding(.bottom)
    }
    
//    MARK: DateSelector
    @ViewBuilder
    private func makeDateSelectorContent(from date: Date, string: String, month: String) -> some View {
        let activeDay = date.matches(currentDay, to: .day)
        
        if activeDay {
            VStack {
                UniversalText(string, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, wrap: false, scale: true)
                UniversalText( month, size: Constants.UIDefaultTextSize, font: Constants.titleFont, wrap: false, scale: true )
            }
                .overlay( VStack {
                    Circle()
                    .universalForegroundColor()
                        .frame(width: 10, height: 10)
                        .offset(y: -50)
                })
        } else {
            UniversalText(string, size: Constants.UISubHeaderTextSize, font: Constants.mainFont, wrap: false, scale: true)
                .overlay {
                    if date.isFirstOfMonth() && !currentDay.matches(date, to: .day) {
                        UniversalText( month, size: Constants.UIDefaultTextSize, font: Constants.mainFont, wrap: false, scale: true )
                            .offset(y: -60)
                    }
                }
                .padding(.horizontal, 2)
        }
    }
    
    @ViewBuilder
    private func makeDateSelector(from date: Date) -> some View {
        
        let string = date.formatted(.dateTime.day(.twoDigits))
        let month = date.formatted(.dateTime.month(.abbreviated)).lowercased()
    
        makeDateSelectorContent(from: date, string: string, month: month)
            .if(currentDay.matches(date, to: .day)) { view in
                view
                    .padding()
                    .background(
                        Rectangle()
                            .cornerRadius(Constants.UIDefaultCornerRadius)
                            .universalForegroundColor()
                            .matchedGeometryEffect(id: "string", in: calendarPageView) )
            }
            .onTapGesture { setCurrentDay(with: date) }
    }
    
    @ViewBuilder
    private func makeDateSelectors() -> some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal) {
                HStack(alignment: .center) {
                    ForEach(-100..<100) { i in
                        let date: Date = (Date.now) - (Double( 3 - i ) * Constants.DayTime)
                        makeDateSelector(from: date)
                            .id(i)
                    }
                }
                .onAppear() {
                    reader.scrollTo(0, anchor: .leading)
                }.onChange(of: currentDay) { newValue in
                    if newValue.matches(Date.now, to: .day) {
                        withAnimation { reader.scrollTo(0, anchor: .leading) }
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
    
//    MARK: Headers
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            UniversalText( "Today's Recall", size: Constants.UITitleTextSize, font: Constants.titleFont, wrap: false, true, scale: true )
            Spacer()
            
            ResizeableIcon(icon: "person", size: Constants.UIDefaultTextSize)
                .secondaryOpaqueRectangularBackground()
                .padding(.leading)
                .onTapGesture { showingProfileView = true }
        }
        
        makeDateLabel()
    }
    
    
//    MARK: Body
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            makeHeader()
            
            HStack {
                makeDateSelectors()
                
                LargeRoundedButton("recall", icon: "arrow.up") { showingCreateEventView = true }
            }
        
            GeometryReader { geo in
                CalendarContainer(at: $currentDay, with: Array(events), from: 0, to: 24, geo: geo, swipeDirection: $swipeDirection)
            }
        }
        .padding()
        .sheet(isPresented: $showingCreateEventView) {
            CalendarEventCreationView.makeEventCreationView(currentDay: currentDay)
        }
        .sheet(isPresented: $showingProfileView) {
            ProfileView(appPage: $appPage)
        }
        .universalBackground()
        
    }
    
}
