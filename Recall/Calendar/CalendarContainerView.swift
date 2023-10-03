//
//  CalendarContinerView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI

struct CalendarContainer: View {
    
//    MARK: CalendarView
    private struct CalendarView: View {
        
        @ViewBuilder
        func makeTimeMarker(hour: CGFloat, label: String, color: Color) -> some View {
            VStack {
                HStack(alignment: .top) {
                    if showingTimeMarker {
                        UniversalText( label, size: Constants.UISmallTextSize, font: Constants.mainFont, lighter: true  )
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(color)
                }
                .id( Int(hour.rounded(.down)) )
                .offset(y: CGFloat(hour - CGFloat(startHour)) * spacing )
                Spacer()
            }
        }
        
        private func makeHourLabel( from hour: Int ) -> String {
            if hour == 0 { return "12AM" }
            if hour < 12 { return "\(hour)AM" }
            if hour == 12 { return "12PM" }
            if hour > 12 { return "\(hour - 12)PM" }
            return ""
        }
        
//        MARK: CalendarView vars
        let day: Date
        let spacing: CGFloat
        
        let startHour: Int
        let endHour: Int
        
        let showingCurrentTimeMarker: Bool
        let showingTimeMarker: Bool
        
        init( day: Date, spacing: CGFloat, startHour: Int, endHour: Int, showingCurrentTimeMarker: Bool = true, showingTimeMarker: Bool = true ) {
            self.day = day
            self.spacing = spacing
            self.startHour = startHour
            self.endHour = endHour
            self.showingCurrentTimeMarker = showingCurrentTimeMarker
            self.showingTimeMarker = showingTimeMarker
        }
        
        var body: some View {
            ZStack(alignment: .top) {
                ForEach(startHour..<endHour, id: \.self) { hr in
                    makeTimeMarker(hour: CGFloat(hr), label: makeHourLabel(from: hr).uppercased(), color: .gray.opacity(0.4))
                }
                
                if showingCurrentTimeMarker {
                    makeTimeMarker(hour: CGFloat(Date.now.getHoursFromStartOfDay()), label: "", color: .red)
                }
            }
        }
    }
    
//    MARK: CalendarDateView
//    This is an individual date view, it will display the events and calendar on that date
//    it will also communicate interactions such as dragging
    private struct CalendarDateView: View {
        
        let currentDay: Date
        
        let events: [RecallCalendarEvent]
        
//        sizing vars
        let geo: GeometryProxy
        let maxWidth: CGFloat
        let startHour: Int
        let endHour: Int
        
//        calendar control vars
        @Binding var dragging: Bool
        @Binding var slideDirection: AnyTransition.SlideDirection
        
        let showingTimeMarker: Bool
        
        private func filterEvents() -> [RecallCalendarEvent] {
            events.filter { event in
                event.startTime.matches(currentDay, to: .day) &&
                event.startTime.matches(currentDay, to: .month) &&
                event.startTime.matches(currentDay, to: .year)
                
            }
        }
        
//        MARK: CalendarDateView body
        var body: some View {
            
            let spacing = geo.size.height / CGFloat( endHour - startHour )
            
            ZStack(alignment: .topLeading) {
                
                CalendarView(day: currentDay,
                             spacing: spacing,
                             startHour: startHour,
                             endHour: endHour,
                             showingTimeMarker: showingTimeMarker)
                
                Group {
                    let filtered = filterEvents()
                    
                    ForEach( filtered, id: \.self ) { event in
                        CalendarEventPreviewView(event: event,
                                                 spacing: spacing,
                                                 geo: geo,
                                                 maxWidth: maxWidth,
                                                 startHour: startHour,
                                                 events: filtered,
                                                 dragging: $dragging)
                    }
                    .padding(.leading, showingTimeMarker ? 40 : 0)
                }
                .if( slideDirection == .right ) { view in view.transition(AnyTransition.slideAwayTransition(.right)) }
                .if( slideDirection == .left ) { view in view.transition(AnyTransition.slideAwayTransition(.left)) }
                
                Rectangle()
                    .foregroundColor(.white)
                    .opacity( dragging ? 0.01 : 0 )
                    .onTapGesture { dragging = false }
                    .zIndex( 1 )
            }
            .frame(height: geo.size.height)
            .padding(.bottom, Constants.UIBottomOfPagePadding)
        }
    }
    
    
//    MARK: CalendarDatesScroller
//    This is the scrolling VStack that wraps a calendar date view
//    It also controls the gesture state of those views, such as preventing the screen from scroll as a user resizes an event
    private struct CalendarDatesScroller<Content: View>: View {
        
        @State var dragging: Bool = false
    
//        This variable is mainly for styling this view in different ways
        let background: Bool
        
        let contentBuilder: ( Binding<Bool> ) -> Content
        
        init(background: Bool, contentBuilder: @escaping ( Binding<Bool> ) -> Content ) {
            self.background = background
            self.contentBuilder = contentBuilder
        }
        
    //    MARK: Gestures
    //    This doesn't do anything right now, because the horizontal gestures are being taken up by the tabView,
    //    mayble Ill remove those later ?
        private var swipeGesture: some Gesture {
            DragGesture(minimumDistance: 30)
                .onChanged{ dragValue in }
                .onEnded { dragValue in }
        }
        
        private func makeZoomGesture(geo: GeometryProxy) -> some Gesture {
            MagnificationGesture()
                .onChanged { scaleValue in dragging = true }
                .onEnded { value in dragging = false }
            }
            
        
//        MARK: CalendarDatesScroller body
        var body: some View {
            
            ScrollViewReader { value in
                ScrollView {
                    contentBuilder( $dragging )
                }
                .scrollDisabled(dragging || background)
                .onAppear() {
                    if background { return }
                    let id = Int(Date.now.getHoursFromStartOfDay().rounded(.down) )
                    value.scrollTo( id, anchor: .center )
                }
                .if(background) { view in
                    view.opaqueRectangularBackground(7, stroke: true)
                }
            }
            .onTapGesture { }
            .highPriorityGesture(swipeGesture, including: dragging ? .subviews : .all)
        }
    }


    
//    MARK: MacOSContainer
//    This is the entire calendar page for macOS
    struct MacOSContainer: View {
        
        @Binding var currentDay: Date
        @Binding var slideDirection: AnyTransition.SlideDirection
//        Slide direction needs to be a binding, because the calendar page view for iOS needs to control it from the date picker
//        the dragging variable can be stored in the scroller, because it is never needed in the CalendarPage
        
        let events: [RecallCalendarEvent]
        
//        View options
        let geo: GeometryProxy
        let background: Bool
        
        
        private func makeDateLabel(from date: Date) -> String {
            date.formatted(date: .abbreviated, time: .omitted)
        }
        
        var body: some View {
        
                
            let numberOfDays: Int = Int((geo.size.width / 200).rounded(.down))

            CalendarDatesScroller(background: background) { dragging in
                
                HStack {
                    ForEach( 0..<numberOfDays, id: \.self ) { i in
                        
                        let date = currentDay - (Double(numberOfDays - i) * Constants.DayTime)
                        
                        VStack(alignment: .leading) {
                            
                            
                            UniversalText( makeDateLabel(from: date), size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                                .padding(.bottom, 5)
                            
                            CalendarDateView(currentDay: date,
                                             events: events,
                                             geo: geo,
                                             maxWidth: geo.size.width / CGFloat(numberOfDays),
                                             startHour: 0,
                                             endHour: 24,
                                             dragging: dragging,
                                             slideDirection: $slideDirection,
                                             showingTimeMarker: i == 0 )
                        }
                        
                        
                    }
                }
                .padding(.bottom, 20)
                
            }
        }
        
    }
    
    

//    MARK: vars
    let geo: GeometryProxy
    let scale: CGFloat
    let events: [RecallCalendarEvent]
    
    let startHour: Int
    let endHour: Int
    
    let background: Bool
    
    private var height: CGFloat {
        if overrideHeight == nil { return geo.size.height * scale }
        else { return overrideHeight! }
    }
    let overrideHeight: CGFloat?
    
    @State var dragging: Bool = false
    @Binding var currentDay: Date
    
    @Binding var slideDirection: AnyTransition.SlideDirection
//    @Binding var transition: AnyTransition
    
    @Namespace private var animation
    
    init( at currentDay: Binding<Date>, with events: [RecallCalendarEvent], from startHour: Int, to endHour: Int, geo: GeometryProxy, scale: CGFloat = 2, slideDirection: Binding<AnyTransition.SlideDirection> = Binding { .right } set: { _, _ in }, background: Bool = false, overrideHeight: CGFloat? = nil ) {
        self.events = events
        self.startHour = startHour
        self.endHour = endHour
        self.geo = geo
        self.scale = scale
        self.background = background
        self.overrideHeight = overrideHeight
        self._currentDay = currentDay
        self._slideDirection = slideDirection
    }
    
    
    //    MARK: Body
    var body: some View {
        VStack {
            
            MacOSContainer(currentDay: $currentDay,
                           slideDirection: $slideDirection,
                           events: events,
                           geo: geo,
                           background: background)
            
        }
    }
}
