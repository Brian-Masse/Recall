//
//  CalendarContinerView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI

struct CalendarContainer: View {
    
//   MARK: Calendar View
    private struct CalendarView: View {
        private func makeHourLabel( from hour: Int ) -> String {
            if hour == 0 { return "12AM" }
            if hour < 12 { return "\(hour)AM" }
            if hour == 12 { return "12PM" }
            if hour > 12 { return "\(hour - 12)PM" }
            return ""
        }
        
        let day: Date
        
        let hoursToDisplay: CGFloat
        let spacing: CGFloat
        
        var body: some View {
            VStack {
                
                ZStack(alignment: .top) {
                    ForEach(0..<Int(hoursToDisplay), id: \.self) { hr in
                        VStack {
                            HStack(alignment: .top) {
                                UniversalText( makeHourLabel(from: hr).uppercased(), size: Constants.UISmallTextSize, lighter: true  )
                                
                                Rectangle()
                                    .frame(height: 1)
                                    .universalTextStyle()
                            }
                            .offset(y: CGFloat(hr) * spacing )
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    let geo: GeometryProxy
    let events: [RecallCalendarEvent]
    
    @Binding var dragging: Bool
    @State var currentDay: Date = .now
    
    private func filterEvents() -> [RecallCalendarEvent] {
        events.filter { event in
            Calendar.current.isDate(event.startTime, equalTo: currentDay, toGranularity: .day)
        }
    }
    
//    MARK: Gestures
//    This doesn't do anything right now, because the horizontal gestures are being taken up by the tabView,
//    mayble Ill remove those later ?
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { dragValue in
                if dragValue.translation.width < 0 { currentDay -= Constants.DayTime }
                if dragValue.translation.width > 0 { currentDay += Constants.DayTime }
            }
    }
    
    
//    MARK: Body
    
    var body: some View {
   
        let height = geo.size.height * 2
        let hoursToDisplay:CGFloat = 24
        let spacing = height / hoursToDisplay
        
        VStack {
            
            HStack {
                Image(systemName: "chevron.left").rectangularBackgorund().onTapGesture { currentDay -= Constants.DayTime }
                Spacer()
                UniversalText( currentDay.formatted(date: .abbreviated, time: .omitted), size: Constants.UIDefaultTextSize, true )
                Spacer()
                Image(systemName: "chevron.right").rectangularBackgorund().onTapGesture { currentDay += Constants.DayTime }
            }
            
            ZStack(alignment: .top) {
                
                CalendarView(day: currentDay, hoursToDisplay: hoursToDisplay, spacing: spacing)
                
                ForEach( filterEvents(), id: \.self ) { component in
                    CalendarEventPreviewView(component: component, spacing: spacing, dragging: $dragging)
                }
                .padding(.horizontal)
                .padding(.leading)
            }
            .frame(height: height)
            .gesture(swipeGesture)
        }
    }
}
