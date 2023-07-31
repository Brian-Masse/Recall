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
            .padding(5)
            .onTapGesture { setCurrentDay(with: date) }
    }
    
    
    private func setCurrentDay(with date: Date) {
        if date > currentDay { swipeDirection = .right }
        else { swipeDirection = .left }
        
        withAnimation { currentDay = date }
    }
    
//   MARK: Body
    @ObservedResults( RecallCalendarEvent.self ) var events
    
    @State var showingCreateEventView: Bool = false
    @State var currentDay: Date = .now
    @State var swipeDirection: AnyTransition.SlideDirection = .right

    @Namespace private var calendarPageView
    
    var body: some View {
        
        VStack(alignment: .leading) {

            UniversalText( "Today's Recall", size: Constants.UITitleTextSize, font: Constants.titleFont, true )
            UniversalText( Date.now.formatted(date: .abbreviated, time: .omitted), size: Constants.UIDefaultTextSize, font: Constants.mainFont, lighter: true )
                .onTapGesture { setCurrentDay(with: .now) }
                .padding(.bottom)
            
            HStack(alignment: .center) {
                ForEach(0..<3) { i in
                    let date: Date = currentDay - (Double( 3 - i ) * Constants.DayTime)
                    makeDateSelector(from: date)
                }
                
                let string = currentDay.formatted(.dateTime.day(.twoDigits))
                UniversalText(string, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, wrap: false)
                    .tintRectangularBackground()
                    .overlay( VStack {
                        if currentDay.matches(.now, to: .day) {
                            Circle()
                                .foregroundColor(Colors.tint)
                                .frame(width: 10, height: 10)
                                .offset(y: -40)
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
            CalendarEventCreationView(editing: false,
                                      event: nil,
                                      title: "",
                                      notes: "",
                                      startTime: .now,
                                      endTime: .now + Constants.HourTime,
                                      day: currentDay,
                                      category: RecallCategory(),
                                      goalRatings: Dictionary())   
        }
        .universalBackground()
        
    }
    
}
