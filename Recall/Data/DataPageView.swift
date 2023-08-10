//
//  DataPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI
import RealmSwift


struct DataPageView: View {
    
    enum DataBookMark: String, Identifiable, CaseIterable {
        case Overview
        case Events
        case Goals
        
        var id: String { self.rawValue }
    }
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeContentsButton(label: String, proxy: ScrollViewProxy) -> some View {
        HStack {
            Image(systemName: "arrow.up.forward")
            UniversalText(label, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, wrap: false)
        }
        .tintRectangularBackground()
        .onTapGesture { withAnimation { proxy.scrollTo(label, anchor: .top) }}
    }
    
    
    
    @ObservedResults( RecallCalendarEvent.self ) var events
    @ObservedResults( RecallCategory.self ) var tags
    @ObservedResults( RecallGoal.self ) var goals
    
//    MARK: Body
    
    var body: some View {
        
        let arrEvents = Array(events)
//        let arrTags = Array(tags)
        let arrGoals = Array(goals)
        
        VStack(alignment: .leading) {
            
            UniversalText("Data", size: Constants.UITitleTextSize, font: Constants.titleFont)
            
            ScrollViewReader { value in
                ScrollView(.vertical) {
                    
                    LazyVStack(alignment: .leading) {
                        
                        UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach( DataBookMark.allCases ) { content in
                                    makeContentsButton(label: content.rawValue, proxy: value)
                                }
                            }
                        }.opaqueRectangularBackground()
                        
                        
                        EventsDataSection(events: arrEvents)
                        GoalsDataSection(events: arrEvents, goals: arrGoals)
                        
                        
                        Spacer()
                        
                    }
                }
            }
        }
        .padding(7)
        .universalColoredBackground(Colors.tint)
    }
}
