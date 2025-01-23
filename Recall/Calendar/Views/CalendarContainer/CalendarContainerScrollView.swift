//
//  CalendarContainerScrollView.swift
//  Recall
//
//  Created by Brian Masse on 1/22/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - CalendarContainerScrollView
struct CalendarContainerScrollView<C: View>: View {
    
    @ObservedObject private var viewModel = RecallCalendarContainerViewModel.shared
    
    private let itemCount: Int
    @State private var coloumnCount: Double = 2
    
    @State private var currentIndex: Int = 0
    
    @State private var scrollPosition: ScrollPosition = .init(idType: Int.self)
    
    private let calendarCycleCount: Int = 5
    @State private var currentCalendarCycle: Int = 0
    
    let contentBuilder: (Int) -> C
    
    init( itemCount: Int, @ViewBuilder contentBuilder: @escaping (Int) -> C ) {
        self.itemCount = itemCount
        self.contentBuilder = contentBuilder
    }
    
//    MARK: convertFromLeadingIndexSystemToTrailing
//    the views, from left to right are indexed 0 to itemCount
//    however, because the calendar is pinned to the right, it makes sense for the right most view to be 0-indexed.
//    the currentIndex uses this trailingAlignment index system.
//    to scroll properly and display the index properly, a leadingIndexSystem needs to be translated into a TrailingIndexSystem
    private func convertFromLeadingIndexSystemToTrailing(from index: Int) -> Int {
        self.itemCount - 2 - index
    }
    
//    MARK: setCurrentIndex
//    any change to the currentIndex should be passed onto the viewModel
//    the id passed into this function should be leadingAligned
    private func setCurrentIndex(to index: Int) {
        if index == self.currentIndex { return }
        
        self.currentIndex = convertFromLeadingIndexSystemToTrailing(from: index)
        let date = Date.now - Double(currentIndex) * Constants.DayTime
        
        viewModel.setCurrentDay(to: date, scrollToDay: false)
    }
    
//    MARK: ScrollTo
//    This is the function responsible for moving the ScrollView to another view
//    It can be invoked by toggling the shouldScrollCalendar parameter in the viewModel
//    the id passed into this function should be leadingAligned
    private func scrollTo(id: Int, in width: Double, shouldAnimate: Bool = true) {
        setCurrentIndex(to: id)
        let trailingIndex = convertFromLeadingIndexSystemToTrailing(from: id)
        let position = Double(trailingIndex) * width / coloumnCount
        
        if shouldAnimate { withAnimation {
            scrollPosition.scrollTo( x: position)
        } } else {
            scrollPosition.scrollTo( x: position )
        }
    }
    
    @ViewBuilder
    private func makeScrollView(in width: Double) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                
                ForEach( 0..<itemCount, id: \.self ) { index in
                    contentBuilder(convertFromLeadingIndexSystemToTrailing(from: index))
                        .padding(.horizontal, 2)
                    .frame(width: width / coloumnCount)
                }
            }
            .scrollTargetLayout()
        }
        .onAppear { scrollTo(id: currentIndex, in: width, shouldAnimate: false) }
        
        .scrollTargetBehavior(.viewAligned)
        
        .scrollPosition($scrollPosition)
        .defaultScrollAnchor(.trailing)
    }
    
    var body: some View {
        
        GeometryReader { geo in
            VStack {
//                Text( "\(scrollPosition.viewID(type: Int.self))" )
//                Text( "\(currentIndex)" )
//                Text( "\(itemCount)" )
//                
//                Text("Jump")
//                    .onTapGesture {
//                        let index = Int.random(in: 0..<itemCount)
//                        
////                        print("\(index)")
//                        
//                        let modifier = 0
////                        abs(index - currentIndex) >= 10 ? 1 : 0
//                        
//                        
//                        print(index)
//                        scrollTo(id: index, in: geo.size.width)
//                        
//                    }
//                
//                Text("Toggle")
//                    .onTapGesture {
//                        
//                        coloumnCount = coloumnCount == 2 ? 1 : 2
//                        
//                        withAnimation {
//                            currentCalendarCycle = (currentCalendarCycle + 1) % calendarCycleCount
//                        }
//                    }
//                        
//                        
                ForEach( 0..<calendarCycleCount, id: \.self ) { i in
                    if i == currentCalendarCycle {
                        makeScrollView(in: geo.size.width)
                    }
                }
            }
            .onChange(of: viewModel.scrollCalendar) { self.scrollTo(id: viewModel.getIndexFromCurrentDay(), in: geo.size.width) }
            .onChange(of: scrollPosition) { oldValue, newValue in
                if let id = newValue.viewID(type: Int.self) { setCurrentIndex(to: id) }
            }
        }
    }
}

//#Preview {
//    CalendarContainerScrollView()
//}

