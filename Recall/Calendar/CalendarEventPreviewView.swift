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
    
    private let blockCoordinateSpaceKey: String = "blockCOordinateSpace"
    private let holdDuration: Double = 0.1

    private enum ResizeDirection: Int {
        case up = 1
        case down = -1
    }
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedRealmObject var event: RecallCalendarEvent
    
    let spacing: CGFloat
    let geo: GeometryProxy
    let startHour: Int
    let events: [RecallCalendarEvent]
    
    var overlapData: RecallCalendarEvent.OverlapData { event.getOverlapData(in: geo.size.width - 20, from: events) }
    
    @ObservedRealmObject var index = RecallModel.index
    
    @State var startDate: Date = .now
    @State var endDate: Date = .now
    @State var length: CGFloat = 0  //measured in hours
    @State var roundedStartDate: Date = .now
    
    @Binding var dragging: Bool
    @State var moving: Bool = false
    @State var resizing: Bool = false //used to block the movement gesture while resizing
    
    @State var showingEvent: Bool = false
    @State var showingEditingScreen: Bool = false
    @State var showingDeletionAlert: Bool = false
    
    @Binding var selecting: Bool
    @Binding var selection: [RecallCalendarEvent]
    
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
    private func clampPosition(_ pos: CGFloat ) -> CGFloat {
        min( max( 0, pos ), (24 * spacing) - 1 )
    }
    
    private func beginMoving() {
        dragging = true
        moving = true
    }
    
    private func beginResizing() {
        dragging = true
        resizing = true
    }
    
    private func getWidth() -> CGFloat {
        max(overlapData.width, 1)
    }
    
    private func getHeight() -> CGFloat {
        max(CGFloat(length) * spacing, 10)
    }
    
    private func getVerticalOffset(from startDate: Date) -> CGFloat {
        max(CGFloat(startDate.getHoursFromStartOfDay() - Double(startHour)) * spacing, 0)
    }
    
    private func getHorizontalOffset( ) -> CGFloat {
        overlapData.offset
    }
    
    private func resetEditingControls() {
        resizing = false
        moving = false
    }
    
//    MARK: Drag
    private var drag: some Gesture {
        DragGesture(coordinateSpace: .named(blockCoordinateSpaceKey))
            .onChanged { dragGesture in
                if !moving || resizing { return }
                startDate = getTime(from: clampPosition(dragGesture.location.y))
                endDate   = startDate + (length * Constants.HourTime)
                
                roundedStartDate = getNearestTime(from: clampPosition(dragGesture.location.y), to: index.dateSnapping)
            }
            .onEnded { dragGesture in
                if dragging && !resizing {
                    dragging = false
                    moving = false
                    event.updateDate(startDate: roundedStartDate, endDate: roundedStartDate + ( length * Constants.HourTime ) )
                }
            }
    }
    
//    MARK: Resize
    private func resizeGesture(_ direction: ResizeDirection) -> some Gesture {
        DragGesture( coordinateSpace: .named(blockCoordinateSpaceKey) )
            .onChanged { dragGesture in
                if !dragging || !resizing { return }
                if direction == .up {
                    startDate        = min(getTime(from: clampPosition(dragGesture.location.y)), endDate - Constants.HourTime)
                    roundedStartDate = min(getNearestTime(from: clampPosition(dragGesture.location.y), to: index.dateSnapping), endDate - Constants.HourTime)
                    length           = endDate.timeIntervalSince(startDate) / Constants.HourTime
                } else {
                    endDate             = max(getTime(from: clampPosition(dragGesture.location.y)), startDate + Constants.HourTime)
                    let roundedEndDate  = max(getNearestTime(from: clampPosition(dragGesture.location.y), to: index.dateSnapping, roundingRule: .up), startDate + Constants.HourTime)
                    length              = endDate.timeIntervalSince(startDate) / Constants.HourTime
                    roundedStartDate    = roundedEndDate - length * Constants.HourTime
                }
            }
            .onEnded { dragGesture in
                resizing = false
                dragging = false
                if direction == .up { event.updateDate(startDate: roundedStartDate)
                } else { event.updateDate(endDate: roundedStartDate + length * Constants.HourTime ) }
            }
    }
    
//    When a user begins dragging or resizing the box that appears to show them where it will be snapped to needs to make sure that its initial position is correct
    private func prepareMovementSnapping() {
        roundedStartDate = startDate
    }
    
//    MARK: Struct Methods
//    this translates a position into a date
//    it is involved in placing events on the timeline correctly
    private func getTime(from position: CGFloat) -> Date {
        let pos = position + ( CGFloat(startHour) * spacing )
        let hour = (pos / spacing).rounded(.down) + CGFloat(startHour)
        let minutes = ((pos / spacing) - hour) * CGFloat(Constants.MinuteTime)
        
        return Calendar.current.date(bySettingHour: Int(hour), minute: Int(minutes), second: 0, of: startDate) ?? .now
    }
    
//    this snaps the time to a set position based on the users preferences
    private func getNearestTime(from position: CGFloat, to timeRounding: TimeRounding, roundingRule: FloatingPointRoundingRule = .down ) -> Date {
        let pos = position + ( CGFloat(startHour) * spacing )
        var hour = (pos / spacing).rounded(.down)
        let minutes = ((pos / spacing) - hour)
        var roundedMinutes = ((minutes * CGFloat(timeRounding.rawValue)).rounded(roundingRule) / CGFloat(timeRounding.rawValue)) * CGFloat(Constants.MinuteTime)
        
        if roundedMinutes == 60 {
            roundedMinutes = 0
            hour += 1
        }
        
        return Calendar.current.date(bySettingHour: Int(hour), minute: Int(roundedMinutes), second: 0, of: startDate) ?? .now
    }

    private func setup() {
        startDate = event.startTime
        endDate = event.endTime
        
        let startTime = event.startTime.getHoursFromStartOfDay()
        let endTime = event.endTime.getHoursFromStartOfDay()
        length = endTime - startTime
    }
    
//    MARK: Input Response

//    this function runs anyitme a user selects any option from the context menu
//    its meant to disable any features that may be incmpatible with the currently performered action
    @MainActor
    private func defaultContextMenuAction() {
        selecting = false
    }
    
    private func toggleSelection() {
        if let index = selection.firstIndex(where: { selectedEvent in
            selectedEvent == event
        }) {
            selection.remove(at: index)
        } else {
            selection.append( event )
        }
    }
    
    private func onTap() {
        if selecting { withAnimation { toggleSelection() }}
        else { showingEvent = true }
        
        
    }
    
    
//    MARK: Body
    @ViewBuilder
    private func makeLengthHandles() -> some View {
        VStack {
            makeLengthHandle(.up)
            Spacer()
            makeLengthHandle(.down)
        }.frame(height: getHeight() + 120)
    }
    
    @ViewBuilder
    private func makeLengthHandle(_ direction: ResizeDirection) -> some View {
        if resizing {
            Rectangle()
                .foregroundColor(.white.opacity(0.01))
                .onTapGesture { }
                .simultaneousGesture(resizeGesture( direction ))
                .frame(minHeight: 10, maxHeight: 20)
                .overlay(
                    Image(systemName: direction == .up ? "chevron.up" : "chevron.down")
                        .padding(.horizontal)
                        .rectangularBackground(style: .secondary)
                        .offset(y: direction == .up ? 20 : -20)
                        .onTapGesture { }
                        .simultaneousGesture(resizeGesture( direction ))
                )
        }
    }
    
    var body: some View {
        ZStack {
            if moving || resizing {
                Rectangle()
                    .foregroundColor(.red.opacity(0.5))
                    .cornerRadius(Constants.UIDefaultCornerRadius)
                    .frame(width: getWidth(), height: getHeight())
                    .offset(x: getHorizontalOffset(), y: getVerticalOffset(from: roundedStartDate))
            }
        
            CalendarEventPreviewContentView(event: event,
                                            events: events,
                                            width: getWidth(),
                                            height: getHeight(),
                                            selecting: $selecting,
                                            selection: $selection)
                .frame(width: getWidth(), height: getHeight())
                .overlay(makeLengthHandles())
            
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
                        selecting = true
                        selection.append(event)
                    }
                    
                    ContextMenuButton("delete", icon: "trash", role: .destructive) {
                        defaultContextMenuAction()
                        if event.isTemplate { showingDeletionAlert = true }
                        else { event.delete() }
                    }
                }
                .offset(x: getHorizontalOffset(), y: getVerticalOffset(from: startDate))
                
                .onTapGesture { onTap() }
                .simultaneousGesture( drag, including:  !resizing ? .all : .subviews  )
                .coordinateSpace(name: blockCoordinateSpaceKey)
            
                .onAppear { setup() }
                .onChange(of: dragging) { newValue in
                    prepareMovementSnapping()
                    if !newValue { resetEditingControls() } 
                }
                .shadow(radius: (resizing || moving) ? 10 : 0)
                .sheet(isPresented: $showingEditingScreen) {
                    CalendarEventCreationView.makeEventCreationView(currentDay: event.startTime, editing: true, event: event)
                }
                .sheet(isPresented: $showingEvent) {
                    CalendarEventView(event: event, events: events)
                }
            
                .deleteableCalendarEvent(deletionBool: $showingDeletionAlert, event: event)
                .halfPageScreen("Select Events", presenting: $selecting) {
                    EventSelectionEditorView(selecting: $selecting,
                                             selection: $selection)
                }
        }
        .zIndex( resizing || moving ? 5 : 0 )
        
        
    }
}
