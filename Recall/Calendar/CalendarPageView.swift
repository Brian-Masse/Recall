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
    @ViewBuilder
    private func makeDateSelector(from date: Date) -> some View {
        
        let string = date.formatted(.dateTime.day(.twoDigits))
        
        UniversalText(string, size: Constants.UISubHeaderTextSize, font: Constants.mainFont)
            .matchedGeometryEffect(id: string, in: calendarPageView)
            .padding(4)
            .onTapGesture { setCurrentDay(with: date) }
    }
    
    
    private func setCurrentDay(with date: Date) {
        if date > currentDay { swipeDirection = .right }
        else { swipeDirection = .left }
        
        withAnimation { currentDay = date }
    }
    
//   MARK: Body

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
    
    
//    MARK: Body
    
    var body: some View {
        
        VStack(alignment: .leading) {

            HStack {
                UniversalText( "Today's Recall", size: Constants.UITitleTextSize, font: Constants.titleFont, wrap: false, true, scale: true )
                Spacer()
                
                ResizeableIcon(icon: "person", size: Constants.UIDefaultTextSize)
                    .secondaryOpaqueRectangularBackground()
                    .padding(.leading)
                    .onTapGesture { showingProfileView = true }
            }
            
            makeDateLabel()
            
            HStack(alignment: .center) {
                ForEach(0..<3) { i in
                    let date: Date = currentDay - (Double( 3 - i ) * Constants.DayTime)
                    makeDateSelector(from: date)
                }
                
                let string = currentDay.formatted(.dateTime.day(.twoDigits))
                let month = currentDay.formatted(.dateTime.month(.abbreviated)).lowercased()
                VStack {
                    UniversalText(string, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, wrap: false, scale: true)
                    UniversalText( month, size: Constants.UIDefaultTextSize, font: Constants.titleFont, wrap: false, scale: true )
                }
                    .tintRectangularBackground()
                    .overlay( VStack {
                        if currentDay.matches(.now, to: .day) {
                            Circle()
                                .foregroundColor(Colors.tint)
                                .frame(width: 10, height: 10)
                                .offset(y: -50)
                        }
                    })
                
                makeDateSelector(from: currentDay + Constants.DayTime)
//                    .padding(.bottom, 5)
                
                Spacer()
                
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
