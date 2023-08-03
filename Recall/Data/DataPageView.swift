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
    
//    MARK: Body
    
    var body: some View {
        
        let arrEvents = Array(events)
//        let arrTags = Array(tags)
        
        VStack(alignment: .leading) {
            
            UniversalText("Data", size: Constants.UITitleTextSize, font: Constants.titleFont)
            
            ScrollViewReader { value in
                ScrollView(.vertical) {
                    
                    VStack(alignment: .leading) {
                        
                        UniversalText("Quick Actions", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach( DataBookMark.allCases ) { content in
                                    makeContentsButton(label: content.rawValue, proxy: value)
                                }
                            }
                        }.opaqueRectangularBackground()
                        
                        
                        DataCollection("Events") {
                            ActivitiesPerDay("Number of Hours, by tag", with: arrEvents) { event in event.getLengthInHours() }
                            
                            ActivitiesPerDay("Number of events, by tag", with: arrEvents) { _ in 1 }
                            
                        }.id( DataBookMark.Events.rawValue )
                        
                        
                        Spacer()
                        
                    }
                }
            }
        }
        .padding(7)
        .universalColoredBackground(Colors.tint)
    }
}


struct DataCollection<Content: View>: View {
    
    let label: String
    let content: Content
    
    init( _ label: String, @ViewBuilder content: ()->Content ) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( label, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            
            VStack(alignment: .leading) {
                content
            }.opaqueRectangularBackground()
        }
        
    }
    
}
