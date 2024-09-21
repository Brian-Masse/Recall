//
//  TestingCalendarContainer.swift
//  Recall
//
//  Created by Brian Masse on 8/21/24.
//

import Foundation
import SwiftUI
import UIUniversals

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

struct CalendarContainer: View {
    
//    MARK: Calendar
    private func getCalendarMarkLabel(hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? .now
        
        let includeFormat = hour % 12 == 0
        let format = Date.FormatStyle().hour(.defaultDigits(amPM: includeFormat ? .wide : .omitted))
        return date.formatted(format)
    }
    
    @ViewBuilder
    private func makeCalendarMark(hour: Int, minute: Int = 0, includeLabel: Bool = true, opacity: Double = 0.15) -> some View {
        HStack(alignment: .top) {
            
            if includeLabel {
                UniversalText( getCalendarMarkLabel(hour: hour),
                               size: Constants.UISmallTextSize,
                               font: Constants.mainFont  )
                    .lineLimit(1)
                    .frame(width: calendarLabelWidth, alignment: .trailing)
            }
            
            Rectangle()
                .frame(height: 0.5)
                .opacity(opacity)
        }
        .alignmentGuide(VerticalAlignment.top) { _ in
            let timeInterval = Double(hour) *  Constants.HourTime + Double(minute) * Constants.MinuteTime
            return CGFloat(-(timeInterval) / viewModel.scale)
        }
    }
    
    @ViewBuilder
    private func makeCalendar() -> some View {
        ZStack(alignment: .top) {
            ForEach( 0...30, id: \.self ) { i in
                makeCalendarMark(hour: i)
            }
            
            let currentComps = Calendar.current.dateComponents([.hour, .minute], from: .now)
            
            makeCalendarMark(hour: currentComps.hour!, minute: currentComps.minute!, includeLabel: false, opacity: 1)
                .foregroundStyle(.red)
        }
    }
    
//    MARK: Initialization
    @ObservedObject private var viewModel = RecallCalendarViewModel.shared
    
    private let events: [RecallCalendarEvent]
    
    private let calendarLabelWidth: Double = 20
    private let scrollDetectionPadding: Double = 200
    
    private let coordinateSpaceName = "CalendarContainerCoordinateSpace"
    
    init(events: [RecallCalendarEvent]) {
        self.events = events
    }
    
//    MARK: Struct Methods
    private func setCurrentPostIndex(from scrollPosition: CGPoint, in geo: GeometryProxy) {
//        if scrollPosition.x > 0 { return }
        let x = scrollPosition.x
        let proposedIndex = Int(floor(abs(x - calendarLabelWidth - scrollDetectionPadding) / abs(geo.size.width - calendarLabelWidth) * 2))
        let proposedDate = Date.now - (Double(proposedIndex) * Constants.DayTime)
        
        if !self.viewModel.currentDay.matches(proposedDate, to: .day) {
            self.viewModel.setCurrentDay(to: proposedDate, scrollToDay: false)
        }
    }
    
    private func setSubDayIndex(from scrollPosition: Double, in geo: GeometryProxy) {
        let proposedIndex: Int = Int(floor((abs(scrollPosition) / geo.size.width) * 2))
        let index = min(max( 0, proposedIndex ), 2)
        viewModel.setSubDayIndex(to: index)
    }
    
    private func scrollToCurrentDay(proxy: ScrollViewProxy) {
        let index = floor(Date.now.timeIntervalSince(viewModel.currentDay) / Constants.DayTime)
        withAnimation { proxy.scrollTo(Int(index)) }
    }
    
//    MARK: ScaleGesture
    @State private var lastScale: Double = 100
    
    private var scaleGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let proposedScale = lastScale * (1 / value.magnification)
                let difference = proposedScale - lastScale
                let scale = lastScale + (difference / 2)
                
                self.viewModel.setScale(to: scale)
            }
            .onEnded { value in
                self.lastScale = viewModel.scale
            }
    }
    
//    MARK: EventCreationGesture
    @State private var newEvent: RecallCalendarEvent? = nil
    @State private var creatingEvent: Bool = false
    @State private var showingEventCreationView: Bool = false
    
    @State private var newEventoffset: Double = 0
    @State private var newEventResizeOffset: Double = 0
    
    private func cleanEvent() {
        if let newEvent {
            if newEvent.title.isEmpty || newEvent.getTagLabel().isEmpty {
                RealmManager.deleteObject(newEvent) { event in
                    newEvent.title.isEmpty
                }
            }
        }
    }
    
    private func createEvent() {
        let subDayOffset = Double(1 - viewModel.subDayIndex) * Constants.DayTime
        
        let startTime = viewModel.getTime(from: newEventoffset, on: viewModel.currentDay) + subDayOffset
        let endTime = startTime + ( newEventResizeOffset * viewModel.scale )
        
        let blankTag = RecallCategory()
        
        let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                        title: "",
                                        notes: "",
                                        startTime: startTime,
                                        endTime: endTime,
                                        categoryID: blankTag._id,
                                        goalRatings: [:])
        
        self.newEvent = event
        
        RealmManager.addObject(event)
    }
    
    private func createEventHoldGesture(in geo: GeometryProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 1)
            .onEnded { value in withAnimation {
                self.creatingEvent = true
                viewModel.gestureInProgress = true
            } }
            .simultaneously(with: DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName)) )
            .onChanged { value in
                if !viewModel.gestureInProgress && value.first != nil {
                    
                    self.setSubDayIndex(from: Double(value.second?.location.x ?? 0), in: geo)
                    
                    let position: Double = Double(value.second?.location.y ?? 0)
                    self.newEventoffset = viewModel.roundPosition(position,
                                                                                      to: RecallModel.index.dateSnapping)
                    self.newEventResizeOffset = (Constants.HourTime / 4) / viewModel.scale
                    
                    
                } else if viewModel.gestureInProgress {
                    
                    let position = Double(value.second?.location.y ?? 0)
                    let proposedStartPosition = viewModel.roundPosition(position, to: RecallModel.index.dateSnapping)
                    
                    if proposedStartPosition < newEventoffset {
                        withAnimation { self.newEventoffset = proposedStartPosition }
                        
                    } else {
                        let height = value.second?.location.y ?? 0
                        let proposedResizeOffset = viewModel.roundPosition(height, to: RecallModel.index.dateSnapping) - self.newEventoffset
                        
                        let minLength = (Constants.HourTime / 4) / viewModel.scale
                        withAnimation { self.newEventResizeOffset =  max(minLength, proposedResizeOffset)  }
                    }
                }
            }
            .onEnded { _ in withAnimation {
                if !creatingEvent { return }
                
                creatingEvent = false
                viewModel.gestureInProgress = false
                
                if self.newEventResizeOffset != 0 {
                    self.createEvent()
                    self.showingEventCreationView = true
                }
            } }
    }
    
//    MARK: EventCreationPreview
    @ViewBuilder
    private func makeEventCreationPreview(on subDayIndex: Int) -> some View {
        if self.creatingEvent && subDayIndex == viewModel.subDayIndex {
            ZStack {
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                    .stroke(style: .init(lineWidth: 3, lineCap: .round, dash: [5, 10], dashPhase: 15))
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                    .opacity(0.3)
            }
            .opacity(0.3)
            .allowsHitTesting(false)
            .offset(y: newEventoffset)
            .frame(height: newEventResizeOffset)
        }
    }
    
//    MARK: CalendarCarousel
    private func calculateSubDayIndex(on day: Date) -> Int {
        let difference = abs(viewModel.currentDay.timeIntervalSince(day)) + Constants.DayTime
        let proposedIndex = Int(floor( difference / Constants.DayTime ))
        return proposedIndex % 2
    }
    
    @ViewBuilder
    private func makeCalendarCarousel(in geo: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    
                    let dayCount = RecallModel.index.daysSinceFirstEvent()
                    
                    ForEach(0...dayCount, id: \.self) { i in
                        
                        let day = .now - (Double(i) * Constants.DayTime)
                        
                        ZStack(alignment: .top) {
                            CalendarView(events: viewModel.getEvents(on: day),
                                             on: day)
                            makeEventCreationPreview(on: calculateSubDayIndex(on: day))
                        }

                        .padding(.horizontal, 5)
                        .border(.green)
                        .frame(width: (geo.size.width - calendarLabelWidth) / 2)
                        .id(i)
                        .task { await viewModel.loadEvents(for: day, in: events) }
                    }
                }
                .background(GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named(coordinateSpaceName)).origin)
                })
                .scrollTargetLayout()
                
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in setCurrentPostIndex(from: value, in: geo) }
                .onAppear { scrollToCurrentDay(proxy: proxy) }
                .onChange(of: viewModel.shouldScrollCalendar) {  scrollToCurrentDay(proxy: proxy) }
                .onChange(of: events) { oldValue, newValue in
                    viewModel.invalidateEvents(newEvents: newValue)
                }
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollDisabled(viewModel.gestureInProgress)
            
        }
        .padding(.leading, calendarLabelWidth)
    }
    
//    MARK: Body
    var body: some View {
        VStack {
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
                        ZStack(alignment: .top) {
                            makeCalendar()
                            
                            makeCalendarCarousel(in: geo)
                            
                            VStack {
                                Spacer()
                                
                                Rectangle()
                                    .frame(height: 10)
                                    .foregroundStyle(.clear)
                                    .allowsHitTesting(false)
                                    .id("scrollTarget")
                                
                                Spacer()
                            }
                            
                            Text("\(viewModel.subDayIndex)")
                        }
                        .padding(.bottom, 150)
                        
                        .simultaneousGesture(createEventHoldGesture(in: geo))
                        
                        .coordinateSpace(name: coordinateSpaceName)
                    }
                    .simultaneousGesture(scaleGesture)
                    .scrollDisabled(viewModel.gestureInProgress)
                    .onAppear { proxy.scrollTo("scrollTarget") }
                }
            }
            .onChange(of: showingEventCreationView) { if !showingEventCreationView { cleanEvent() } }
            .sheet(isPresented: $showingEventCreationView) {
                CalendarEventCreationView.makeEventCreationView(currentDay: viewModel.currentDay,
                                                                editing: true,
                                                                event: newEvent)
            }
            .halfPageScreen("Select Events", presenting: $viewModel.selecting) {
                EventSelectionEditorView()
            }
        }
    }
}

#Preview {
    CalendarContainer(events: [])
}
