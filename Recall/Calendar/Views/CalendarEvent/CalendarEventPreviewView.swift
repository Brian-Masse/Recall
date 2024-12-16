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
    @Namespace private var namespace
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var viewModel: RecallCalendarContainerViewModel = RecallCalendarContainerViewModel.shared
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    @ObservedRealmObject var event: RecallCalendarEvent
    @ObservedRealmObject var index = RecallModel.index
    
    let events: [RecallCalendarEvent]
    
    let includeGestures: Bool

    init( event: RecallCalendarEvent, events: [RecallCalendarEvent], includeGestures: Bool = true) {
        self.event = event
        self.events = events
        self.includeGestures = includeGestures
    }
    
    @State private var moveOffset: Double = 0
    @State private var resizeOffset: Double = 0
    @State private var resizeDirection: ResizeDirection = .up
    
    @State private var moving: Bool = false //local variables
    @State private var resizing: Bool = false //used to block the movement gesture while resizing

    @State private var beingDeleted: Bool = false
    @State private var showingDeletionAlert: Bool = false
    @State private var indexOfEventInEvents: Int = 0
    
    
//    MARK: Convenience Functions
    
    @MainActor
    private func duplicate() {
        let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                        title: event.title,
                                        notes: event.notes,
                                        urlString: event.urlString,
                                        startTime: event.startTime + Constants.HourTime,
                                        endTime: event.endTime + Constants.HourTime,
                                        categoryID: event.category!._id,
                                        goalRatings: RecallCalendarEvent.translateGoalRatingList(event.goalRatings))
        RealmManager.addObject(event)
        
    }
    
    private func findEvent() async {
        if let index = events.firstIndex(where: { $0.identifier() == event.identifier() } ) {
            self.indexOfEventInEvents = index
        }
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
                withAnimation { moveOffset = viewModel.roundPosition(dragGesture.location.y, to: index.dateSnapping) }
            }
            .onEnded { dragGesture in
                if moving && !resizing {
                    let roundedStartTime = viewModel.getTime(from: self.moveOffset, on: event.startTime)
                    let roundedEndTime = roundedStartTime + event.getLengthInHours() * Constants.HourTime
                    
                    event.updateTime(startDate: roundedStartTime, endDate: roundedEndTime )
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
                
                withAnimation { self.resizeOffset = viewModel.roundPosition(dragGesture.location.y, to: index.dateSnapping) }
            }
            .onEnded { dragGesture in
                
                let roundedTime = viewModel.getTime(from: self.resizeOffset, on: event.startTime)
                
                if direction == .up { event.updateTime(startDate: roundedTime) }
                if direction == .down { event.updateTime(endDate: roundedTime) }

                self.resetEditingControls()
            }
    }
    
//    MARK: Input Response
    
    private func onTap() {
//        viewModel.gestureInProgress = false
        Task { await findEvent() }
        
        if viewModel.selecting { viewModel.selectEvent(event) }
        else { coordinator.push(.recallEventCarousel(id: indexOfEventInEvents, events: events, namespace: namespace)) }
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
                
                RecallIcon(direction == .up ? "chevron.up" : "chevron.down")
                    .bold()
            }
            .frame(height: 20)
            .offset(y: direction == .up ? -30 : 30)
            .gesture(resizeGesture( direction ) )
            .padding(7)
        }
    }

    var body: some View {
        GeometryReader { geo in
            
            CalendarEventPreviewContentView(event: event, events: events, height: geo.size.height - 4)
                .safeZoomMatch(id: indexOfEventInEvents, namespace: namespace)
                .opacity(beingDeleted ? 0 : 1)
                .opacity(resizing || moving ? 0.65 : 1)
            
                .background(alignment: resizeDirection == .up ? .bottom : .top) {
                    if resizing || moving {
                        ZStack {
                            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                                .stroke(style: .init(lineWidth: 3, lineCap: .round, dash: [5, 10], dashPhase: 15))
                            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                                .opacity(0.15)
                        }
                            .foregroundStyle(event.getColor())
                            .overlay(makeLengthHandles())
                        
                            .offset(y: getPreviewOffset(in: geo) )
                            .frame(height: getPreviewHeight(in: geo) )
                    }
                }
                .onChange(of: viewModel.gestureInProgress) {
                    if (moving || resizing) && !viewModel.gestureInProgress {
                        resetEditingControls()
                    }
                }
            
                .contextMenu { if includeGestures {
                    ContextMenuButton("move", icon: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left") {
                        resetOffsets(in: geo)
                        beginMoving()
                    }
                    
                    ContextMenuButton("resize", icon: "rectangle.expand.vertical") {
                        resetOffsets(in: geo)
                        beginResizing()
                    }
                    
                    ContextMenuButton("edit", icon: "slider.horizontal.below.rectangle") {
                        coordinator.presentSheet( .eventEdittingView(event: event) )
                    }
                    
                    ContextMenuButton("duplicate", icon: "rectangle.on.rectangle") {
                        duplicate()
                    }
                    
                    ContextMenuButton("favorite", icon: "circle.rectangle.filled.pattern.diagonalline") {
                        event.toggleFavorite()
                    }
                    
                    
                    ContextMenuButton("select", icon: "selection.pin.in.out") {
                        viewModel.selecting = true
                        coordinator.presentSheet(.selectionView) { viewModel.stopSelecting() }
                        viewModel.selectEvent(event)
                    }
                    
                    ContextMenuButton("delete", icon: "trash", role: .destructive) {
                        withAnimation { beingDeleted = true }
                        if event.isTemplate { showingDeletionAlert = true }
                        else { event.delete() }
                    }
                } }
                .onTapGesture { if includeGestures { onTap() }}
            
                .padding(2)
                .simultaneousGesture(drag, including: includeGestures ? .all : .none)
                .task { await findEvent() }

                .deleteableCalendarEvent(deletionBool: $showingDeletionAlert, event: event)
        }
    }
}
