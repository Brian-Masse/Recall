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

struct TestingCalendarContainer: View {
    
//    MARK: Calendar
    private func getCalendarMarkLabel(hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? .now
        
        let includeFormat = hour == 12 || hour == 0
        let format = Date.FormatStyle().hour(.defaultDigits(amPM: includeFormat ? .wide : .omitted))
        return date.formatted(format)
    }
    
    @ViewBuilder
    private func makeCalendarMark(hour: Int, minute: Int = 0, includeLabel: Bool = true) -> some View {
        HStack(alignment: .top) {
            
            if includeLabel {
                Text(getCalendarMarkLabel(hour: hour))
                    .lineLimit(1)
                    .frame(width: calendarLabelWidth, alignment: .trailing)
            }
            
            Rectangle()
                .frame(height: 1)
        }
        .alignmentGuide(VerticalAlignment.top) { _ in
            let timeInterval = Double(hour) *  Constants.HourTime + Double(minute) * Constants.MinuteTime
            return CGFloat(-(timeInterval) / viewModel.scale)
        }
    }
    
    @ViewBuilder
    private func makeCalendar() -> some View {
        ZStack(alignment: .top) {
            ForEach( 0..<24, id: \.self ) { i in
                makeCalendarMark(hour: i)
            }
            
            let currentComps = Calendar.current.dateComponents([.hour, .minute], from: .now)
            
            makeCalendarMark(hour: currentComps.hour!, minute: currentComps.minute!, includeLabel: false)
                .foregroundStyle(.red)
        }
    }
    
//    MARK: Initialization
    @ObservedObject private var viewModel = RecallCalendarViewModel.shared
    
    private let events: [RecallCalendarEvent]
    
    private let calendarLabelWidth: Double = 50
    private let scrollDetectionPadding: Double = 20
    
    private let coordinateSpaceName = "CalendarContainerCoordinateSpace"
    
    init(events: [RecallCalendarEvent]) {
        self.events = events
    }
    
//    MARK: Struct Methods
    private func setCurrentPostIndex(from scrollPosition: CGPoint, in geo: GeometryProxy) {
        let proposedIndex = Int(floor(abs(scrollPosition.x - calendarLabelWidth - scrollDetectionPadding) / abs(geo.size.width - calendarLabelWidth)))
        let proposedDate = Date.now - (Double(proposedIndex) * Constants.DayTime)
        self.viewModel.setCurrentDay(to: proposedDate, scrollToDay: false)
    }
    
    private func scrollToCurrentDay(proxy: ScrollViewProxy) {
        let index = floor(Date.now.timeIntervalSince(viewModel.currentDay) / Constants.DayTime)
        
        withAnimation { proxy.scrollTo(Int(index)) }
    }
    
//    MARK: CalendarCarousel
    @ViewBuilder
    private func makeCalendarCarousel(in geo: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    
                    ForEach(0...10, id: \.self) { i in
                        
                        let day = .now - (Double(i) * Constants.DayTime)
                        
                        //                                    Rectangle()
                        TestCalendarView(events: viewModel.getEvents(on: day),
                                         on: day)
                        //       
//                        .foregroundStyle(.red)
                        .padding(.horizontal, 10)
                        .frame(width: geo.size.width - calendarLabelWidth)
                        .id(i)
                        .task { await viewModel.loadEvents(for: day, in: events) }
                        .coordinateSpace(name: coordinateSpaceName)
                        
                    }
                    .scrollTargetLayout()
                }
                .background(GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named(coordinateSpaceName)).origin)
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in setCurrentPostIndex(from: value, in: geo) }
                .onChange(of: viewModel.shouldScrollCalendar) { _ in scrollToCurrentDay(proxy: proxy) }
                .onChange(of: events) { oldValue, newValue in
                    viewModel.invalidateEvents(newEvents: newValue)
                }
            }
            .scrollTargetBehavior(.paging)
        }.padding(.leading, calendarLabelWidth)
    }
    
//    MARK: Body
    var body: some View {
        VStack {
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .top) {
                        
                        makeCalendar()
                        
                        makeCalendarCarousel(in: geo)
                        
                    }
                    .padding(.bottom, 250)
                }
                .scrollDisabled(viewModel.gestureInProgress)
            }
        }
    }
}

#Preview {
    TestingCalendarContainer(events: [])
}