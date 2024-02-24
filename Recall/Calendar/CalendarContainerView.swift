//
//  CalendarContinerView.swift
//  Recall
//
//  Created by Brian Masse on 7/18/23.
//

import Foundation
import SwiftUI
import UIUniversals
import RealmSwift

class CalendarContainerModel: ObservableObject {
    
    
    @Published private(set) var currentDay: Date = .now
    
    @Published var creatingEvent: Bool = false
    @Published var dragging: Bool = false
    
//    These two variables are designed to manually control the visual length of a singular event
//    When creating an event, the container's drag gesture will control how long it is
//    so it will set this editingLength and editingEvent, so the new event knows how to present itself
//    then once the gesture is done, it will save the event
//    this is to avoid updating the length of the in the DB every frame
    var startingTime: Date = .now
    @Published var editingEvent: RecallCalendarEvent? = nil
    @Published var editingLength: Double = 0            //measured in hours
    
    @Published var selecting: Bool = false
    @Published var selection: [ RecallCalendarEvent ] = []
    
    @MainActor
    func setCurrentDay(to day: Date) {
        self.currentDay = day
    }
    
}


struct CalendarContainer: View {
    
//    MARK: CalendarView
    private struct CalendarView: View {
        
        @ViewBuilder
        func makeTimeMarker(hour: CGFloat, label: String, color: Color) -> some View {
            VStack {
                HStack(alignment: .top) {
                    UniversalText( label, size: Constants.UISmallTextSize, font: Constants.mainFont  )
                    
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
        
        let day: Date
        let spacing: CGFloat
        
        let startHour: Int
        let endHour: Int
        
        var body: some View {
            ZStack(alignment: .top) {
                ForEach(startHour..<endHour, id: \.self) { hr in
                    makeTimeMarker(hour: CGFloat(hr), label: makeHourLabel(from: hr).uppercased(), color: .gray.opacity(0.4))
                }
                
                makeTimeMarker(hour: CGFloat(Date.now.getHoursFromStartOfDay()), label: "", color: .red)
            }
        }
    }
    
//    MARK: Convenience Functions
    private func getTime(from pressLocation: CGFloat) -> Date {
        let position = pressLocation - scrollPosition.y
        
        let hour = (position / spacing).rounded(.down) + CGFloat(startHour)
        let minutes = ((position / spacing) - hour) * CGFloat(Constants.MinuteTime)
        
        let date = Calendar.current.date(bySettingHour: Int(hour), minute: Int(minutes), second: 0, of: containerModel.currentDay) ?? .now
        
        return date
    }
    
    private func getPosition(from time: Date) -> CGFloat {
        let hours = time.getHoursFromStartOfDay()
        
        return hours * spacing
    }
    
    private func filterEvents() -> [RecallCalendarEvent] {
        events.filter { event in
            event.startTime.matches(containerModel.currentDay, to: .day) &&
            event.startTime.matches(containerModel.currentDay, to: .month) &&
            event.startTime.matches(containerModel.currentDay, to: .year)
        }
    }
    
    private func createEvent() {
        
        let startTime = containerModel.startingTime
        let endTime = startTime + ( RecallModel.index.defaultEventLength )
        
        let blankTag = RecallCategory()
        
        let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                        title: "New Event",
                                        notes: "",
                                        startTime: startTime,
                                        endTime: endTime,
                                        categoryID: blankTag._id,
                                        goalRatings: Dictionary())
        
        RealmManager.addObject(event)
        
        containerModel.creatingEvent = true
        containerModel.editingEvent = event
    }
    
//    when a user is done creating an event with the tap and hold gesture, this will fire
//    both to clear related variables for the next event, and to prompt them to edit the current event
    private func endedCreatingGesture() {
        containerModel.dragging = false
        containerModel.creatingEvent = false
        containerModel.editingLength = 0
        containerModel.dragging = false
        containerModel.editingEvent = nil
    }

//    MARK: Swipe Gesture
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 100)
            .onEnded { dragValue in

                if dragValue.translation.width < 0 { slideDirection = .right }
                if dragValue.translation.width > 0 { slideDirection = .left }
                
                withAnimation(.easeInOut(duration: 0.25)) {
                    if dragValue.translation.width < 0 {
                        containerModel.setCurrentDay(to: containerModel.currentDay + Constants.DayTime)
                         }
                    if dragValue.translation.width > 0 { 
                        containerModel.setCurrentDay(to: containerModel.currentDay - Constants.DayTime) }
                }
                
            }
    }
    
//    MARK: LongPressGesture
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .simultaneously(with: DragGesture(minimumDistance: 0))
            .onChanged { value in
//                This will run as soon as the longPress completes
//                This checks that its not already in a dragging state, and that the longPress did actually complete
                if !containerModel.dragging && value.first != nil {
                    
                    containerModel.dragging = true
                    
                    if let position = value.second?.location.y {
                        containerModel.startingTime = getTime(from: position)
                    }
                    
                    createEvent()
                }
            }
            .onEnded { _ in if containerModel.creatingEvent { showingEventEditingView = true } }
    }
    
//    MARK: CreationGesture
    @MainActor
    private var creationGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                if containerModel.dragging {
//                    the hold gesture will have already created the event and stored the start time
                    let minEndTime = containerModel.startingTime + RecallModel.index.defaultEventLength
                    
                    let endTime = max(getTime(from: value.location.y),  minEndTime)

                    let length = endTime.getHoursFromStartOfDay() - containerModel.startingTime.getHoursFromStartOfDay()
                    
                    containerModel.editingLength = Double(length)
                }
            }
            .onEnded { value in if containerModel.creatingEvent {
                let minEndTime = containerModel.startingTime + RecallModel.index.defaultEventLength
                
                let endTime = max(getTime(from: value.location.y),  minEndTime).round(to: .quarter)
                let startTime = containerModel.startingTime.round(to: .quarter)
                
                containerModel.editingEvent?.updateDate(startDate: startTime, endDate: endTime)
                
                showingEventEditingView = true
            } }
    }
    
//    MARK: TapGesture
    private func tapGesture() { withAnimation {
        if containerModel.selecting { containerModel.selecting = false }
        containerModel.dragging = false
    } }
    

//    MARK: vars
    static let sharedContainerModel = CalendarContainerModel()
    
    private let geo: GeometryProxy
    private let scale: CGFloat
    private let events: [RecallCalendarEvent]
    
    private let startHour: Int
    private let endHour: Int
    
    private var spacing: CGFloat { height / CGFloat( endHour - startHour ) }
    private var height: CGFloat { geo.size.height * scale }

    @State var scrollPosition: CGPoint = .zero
    @Binding var slideDirection: AnyTransition.SlideDirection
    
    @State var showingEventEditingView: Bool = false
    
    @ObservedObject var containerModel: CalendarContainerModel = sharedContainerModel

    init(with events: [RecallCalendarEvent], from startHour: Int, to endHour: Int, geo: GeometryProxy, scale: CGFloat = 2, slideDirection: Binding<AnyTransition.SlideDirection> = Binding { .right } set: { _, _ in }) {
        self.events = events
        self.startHour = startHour
        self.endHour = endHour
        self.geo = geo
        self.scale = scale
        self._slideDirection = slideDirection
    }
    
    
//    MARK: Body
    var body: some View {
        VStack {
            ScrollReader($scrollPosition, showingIndicator: false) {
                
                ZStack(alignment: .topLeading) {

                    CalendarView(day: containerModel.currentDay, spacing: spacing, startHour: startHour, endHour: endHour)
                    
                    Group {
                        let filtered = filterEvents()
                        
                        ForEach( filtered, id: \.self ) { event in
                            CalendarEventPreviewView(event: event,
                                                     spacing: spacing,
                                                     geo: geo,
                                                     startHour: startHour,
                                                     events: filtered)
                            .environmentObject(containerModel)
                            
                        }
                        .padding(.leading, 40)
                    }
                    .if( slideDirection == .right ) { view in view.transition(AnyTransition.slideAwayTransition(.right)) }
                    .if( slideDirection == .left ) { view in view.transition(AnyTransition.slideAwayTransition(.left)) }
                    
                    Rectangle()
                        .foregroundColor(.white)
                        .opacity( containerModel.dragging ? 0.01 : 0 )
                        .onTapGesture {
                            containerModel.dragging = false
                            containerModel.selecting = false
                            containerModel.creatingEvent = false
                        }
                        .zIndex( 1 )
                }
                .frame(height: height)
                .padding(.bottom, Constants.UIBottomOfPagePadding)
            }
            .scrollDisabled(containerModel.dragging)

            .onTapGesture { tapGesture() }
            .gesture(longPressGesture)
            .simultaneousGesture( creationGesture )
            .simultaneousGesture(swipeGesture, including: containerModel.dragging ? .subviews : .all)
            
            .sheet(isPresented: $showingEventEditingView,
                   onDismiss: { endedCreatingGesture() }) {
                CalendarEventCreationView
                    .makeEventCreationView(currentDay: containerModel.currentDay,
                                           editing: true,
                                           event: containerModel.editingEvent)
            }
        }
    }
}
