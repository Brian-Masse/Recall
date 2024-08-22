//
//  CalendarEventPreviewView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

//MARK: Time Rounding
enum TimeRounding: Int, CaseIterable, Identifiable {
    case hour = 1
    case halfHour = 2
    case quarter = 4
    
    var id: Int { self.rawValue }
    
    func getTitle() -> String {
        switch self {
        case .hour: return "hour"
        case .halfHour: return "half hour"
        case .quarter: return "quarter hour"
        }
    }
}

//MARK: CalendarEventPreviewview
//Should only be placed ontop of a caldndar container
struct CalendarEventPreviewView: View {
    
    private let coordinateSpaceName = "CalendarContainerCoordinateSpace"
    private let holdDuration: Double = 0.1

    private enum ResizeDirection: Int {
        case up = 1
        case down = -1
    }
    
//    MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var containerModel: CalendarContainerModel
    @ObservedObject var viewModel: RecallCalendarViewModel = RecallCalendarViewModel.shared
    
    @ObservedRealmObject var event: RecallCalendarEvent
    @ObservedRealmObject var index = RecallModel.index
    
    let events: [RecallCalendarEvent]

    init( event: RecallCalendarEvent, events: [RecallCalendarEvent]) {
        self.event = event
        self.events = events
        
        
    }
    
    @State private var moveOffset: Double = 0
    @State private var resizeOffset: Double = 0
    @State private var resizeDirection: ResizeDirection = .up
    
    @State var moving: Bool = false //local variables
    @State var resizing: Bool = false //used to block the movement gesture while resizing
    
    @State var showingEvent: Bool = false
    @State var showingEditingScreen: Bool = false
    @State var showingDeletionAlert: Bool = false
    
     
    
//    MARK: Convenience Functions
    
    @MainActor
    private func duplicate() {
        let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                        title: event.title,
                                        notes: event.notes,
                                        startTime: event.startTime + Constants.HourTime,
                                        endTime: event.endTime + Constants.HourTime,
                                        categoryID: event.category!._id,
                                        goalRatings: RecallCalendarEvent.translateGoalRatingList(event.goalRatings))
        RealmManager.addObject(event)
        
    }
    
//    MARK: Convenience vars
    private func beginMoving() { withAnimation {
        viewModel.gestureInProgress = true
        moving = true
    } }
    
    private func beginResizing() { withAnimation {
        viewModel.gestureInProgress = true
        resizing = true
    } }
    
    private func resetEditingControls() { withAnimation {
        viewModel.gestureInProgress = false
        resizing = false
        moving = false
    } }
    
//    MARK: Drag
    private var drag: some Gesture {
        DragGesture(coordinateSpace: .named(coordinateSpaceName))
            .onChanged { dragGesture in
                if !moving || resizing { return }
                withAnimation { moveOffset = roundPosition(dragGesture.location.y, to: index.dateSnapping) }
            }
            .onEnded { dragGesture in
                if moving && !resizing {
                    let roundedStartTime = getTime(from: self.moveOffset, on: event.startTime)
                    let roundedEndTime = roundedStartTime + event.getLengthInHours() * Constants.HourTime
                    
                    event.updateDate(startDate: roundedStartTime, endDate: roundedEndTime )
                }
                self.resetEditingControls()
            }
    }
    
//    MARK: Resize
    private func resizeGesture(_ direction: ResizeDirection) -> some Gesture {
        DragGesture( coordinateSpace: .named(coordinateSpaceName) )
            .onChanged { dragGesture in
                if moving || !resizing { return }
                self.resizeDirection = direction
                
                withAnimation { self.resizeOffset = roundPosition(dragGesture.location.y, to: index.dateSnapping) }
            }
            .onEnded { dragGesture in
                
                let roundedTime = getTime(from: self.resizeOffset, on: event.startTime)
                
                if direction == .up { event.updateDate(startDate: roundedTime) }
                if direction == .down { event.updateDate(endDate: roundedTime) }

                self.resetEditingControls()
            }
    }
    
//    MARK: Struct Methods
//    this translates a position into a date
//    it is involved in placing events on the timeline correctly
    private func getTime(from position: CGFloat, on date: Date) -> Date {
        let timeInterval = position * viewModel.scale
        let hour = (timeInterval / Constants.HourTime).rounded(.down)
        let minutes = ((timeInterval / Constants.HourTime) - hour) * CGFloat(Constants.MinuteTime)
        
        return Calendar.current.date(bySettingHour: Int(hour), minute: Int(minutes), second: 0, of: date) ?? .now
    }
    
    private func roundPosition(_ position: Double, to timeRounding: TimeRounding) -> Double {
        let hoursInPosition = (position * viewModel.scale) / Constants.HourTime
        let roundedHours = (hoursInPosition * Double(timeRounding.rawValue)).rounded(.down) / Double(timeRounding.rawValue)
        return (roundedHours * Constants.HourTime) / viewModel.scale
        
    }
    
//    MARK: Input Response
//    this function runs anyitme a user selects any option from the context menu
//    its meant to disable any features that may be incmpatible with the currently performered action
    @MainActor
    private func defaultContextMenuAction() { }
    
    private func toggleSelection() {
        if let index = containerModel.selection.firstIndex(where: { selectedEvent in
            selectedEvent == event
        }) {
            containerModel.selection.remove(at: index)
        } else {
            containerModel.selection.append( event )
        }
    }
    
    private func onTap() {
//        if containerModel.selecting { withAnimation { toggleSelection() }}
        showingEvent = true
    }

    
//    MARK: Offets
    private func getPreviewOffset(in geo: GeometryProxy) -> Double {
        let movementOffset = moveOffset - geo.frame(in: .named(coordinateSpaceName)).minY
        return movementOffset
    }
    
    private func getPreviewHeight(in geo: GeometryProxy) -> Double {
        let frame = geo.frame(in: .named(coordinateSpaceName))
        let resizeOffset = resizeOffset - (resizeDirection == .up ? frame.maxY : frame.minY)
        let defaultLength = (event.getLengthInHours() * Constants.HourTime) / viewModel.scale
        return defaultLength + abs(resizeOffset) - frame.height
    }
    
    private func resetOffsets(in geo: GeometryProxy) {
        let frame = geo.frame(in: .named(coordinateSpaceName))
        
        withAnimation {
            moveOffset = frame.minY
            resizeOffset = (resizeDirection == .up ? frame.maxY : frame.minY) + frame.height
        }
    }
    
    
//    MARK: Body
    @ViewBuilder
    private func makeLengthHandles() -> some View {
        VStack {
            makeLengthHandle(.up)
            Spacer()
            makeLengthHandle(.down)
        }
    }
    
    @ViewBuilder
    private func makeLengthHandle(_ direction: ResizeDirection) -> some View {
        if resizing {
            ZStack {
                Rectangle()
                    .foregroundStyle(.clear)
                    .contentShape(Rectangle())
                
                Image(systemName: direction == .up ? "chevron.up" : "chevron.down")
                    .bold()
            }
                .frame(height: 20)
                .offset(y: direction == .up ? -30 : 30)
                .gesture(resizeGesture( direction ))
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            
        
            CalendarEventPreviewContentView(event: event, events: events)
                .opacity(viewModel.gestureInProgress ? 0.5 : 1)
            
                .background(alignment: resizeDirection == .up ? .bottom : .top) {
                    if viewModel.gestureInProgress {
                        ZStack {
                            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                                .stroke(style: .init(lineWidth: 3, lineCap: .round, dash: [5, 10], dashPhase: 15))
                            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                                .opacity(0.3)
                        }
                            .foregroundStyle(event.getColor())
                            .overlay(makeLengthHandles())

                            .onAppear { resetOffsets(in: geo)  }
                            .offset(y: getPreviewOffset(in: geo) )
                            .frame(height: getPreviewHeight(in: geo) )
                    }
                }
            
                .contextMenu {
                    ContextMenuButton("move", icon: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left") {
                        defaultContextMenuAction()
                        beginMoving()
                    }
                    
                    ContextMenuButton("resize", icon: "rectangle.expand.vertical") {
                        defaultContextMenuAction()
                        beginResizing()
                    }
                    
                    ContextMenuButton("edit", icon: "slider.horizontal.below.rectangle") {
                        defaultContextMenuAction()
                        showingEditingScreen = true
                    }
                    
                    ContextMenuButton("duplicate", icon: "rectangle.on.rectangle") {
                        defaultContextMenuAction()
                        duplicate()
                    }
                    
                    ContextMenuButton("favorite", icon: "circle.rectangle.filled.pattern.diagonalline") {
                        defaultContextMenuAction()
                        event.toggleFavorite()
                    }
                    
                    ContextMenuButton("select", icon: "selection.pin.in.out") {
                        defaultContextMenuAction()
                        containerModel.selecting = true
                        containerModel.selection.append(event)
                    }
                    
                    ContextMenuButton("delete", icon: "trash", role: .destructive) {
                        defaultContextMenuAction()
                        if event.isTemplate { showingDeletionAlert = true }
                        else { event.delete() }
                    }
                }
                .onTapGesture { onTap() }

                .gesture(drag)
            
                .shadow(radius: (resizing || moving) ? 10 : 0)
                .sheet(isPresented: $showingEditingScreen) {
                    CalendarEventCreationView.makeEventCreationView(currentDay: event.startTime, editing: true, event: event)
                }
                .sheet(isPresented: $showingEvent) { CalendarEventView(event: event, events: events) }
            
                .deleteableCalendarEvent(deletionBool: $showingDeletionAlert, event: event)
//                .halfPageScreen("Select Events", presenting: $containerModel.selecting) {
//                    EventSelectionEditorView().environmentObject(containerModel)
//                }
        }
        .zIndex( resizing || moving ? 5 : 0 )
        
        
    }
}
