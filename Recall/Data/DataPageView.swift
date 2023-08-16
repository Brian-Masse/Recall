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
    
    @ObservedObject private var dataModel: RecallDataModel = RecallModel.dataModel
    
//    MARK: Body
    
    var body: some View {
        
        let arrGoals = Array(goals)
        
        VStack(alignment: .leading) {
            
            UniversalText("Data", size: Constants.UITitleTextSize, font: Constants.titleFont)

            ScrollViewReader { value in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        
                        UniversalText("Quick Links", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach( DataBookMark.allCases ) { content in
                                    makeContentsButton(label: content.rawValue, proxy: value)
                                }
                            }
                        }.secondaryOpaqueRectangularBackground(7)
                        
                        
                        OverviewDataSection(goals: arrGoals)
                            .environmentObject(dataModel )
                        EventsDataSection()
                            .environmentObject(dataModel )
                        GoalsDataSection(goals: arrGoals)
                            .environmentObject(dataModel )
                        
                        
                        Spacer()
                    }
                    .padding(.bottom, Constants.UIBottomOfPagePadding)
                }
            }
        }
        .padding(7)
        .universalBackground()
    }
}
