//
//  DataPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct QuickLinks<EnumType: CaseIterable>: View where EnumType.AllCases: RandomAccessCollection, EnumType: Identifiable, EnumType:RawRepresentable, EnumType.RawValue == String {
    
    @ViewBuilder
    private func makeContentsButton(label: String, proxy: ScrollViewProxy) -> some View {
        HStack {
            Image(systemName: "arrow.up.forward")
            UniversalText(label, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, wrap: false)
        }
        .tintRectangularBackground()
        .onTapGesture { withAnimation { proxy.scrollTo(label, anchor: .top) }}
    }
    
    let dudContent: EnumType
    let value: ScrollViewProxy
    
    var body: some View {
        UniversalText("Quick Links", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
        ScrollView(.horizontal) {
            HStack {
                ForEach( EnumType.allCases ) { content in
                    makeContentsButton(label: content.rawValue, proxy: value)
                }
            }
        }.secondaryOpaqueRectangularBackground(7)    }
}


struct DataPageView: View {
    
    enum DataBookMark: String, Identifiable, CaseIterable {
        case Overview
        case Events
        case Goals
        
        var id: String { self.rawValue }
    }
    
    
//    MARK: Vars
    let events: [RecallCalendarEvent]
    @ObservedResults( RecallCategory.self ) var tags
    @ObservedResults( RecallGoal.self ) var goals
    
    @ObservedObject private var dataModel: RecallDataModel = RecallModel.dataModel
    
    @Binding var page: MainView.MainPage
    @Binding var currentDay: Date
    
    @State var hide: Bool = true
    
//    MARK: Body
    
    var body: some View {
        
        let arrGoals = Array(goals)
        
        VStack(alignment: .leading) {
            
            UniversalText("Data", size: Constants.UITitleTextSize, font: Constants.titleFont)

            ScrollViewReader { value in
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        
                        QuickLinks(dudContent: DataBookMark.Events, value: value)
                        
                        
//                        if !hide {
                        OverviewDataSection(goals: arrGoals, currentDay: $currentDay, page: $page)
                            .environmentObject(dataModel )
                        
                        EventsDataSection(page: $page, currentDay: $currentDay)
                            .environmentObject(dataModel )
                        
                        GoalsDataSection(goals: arrGoals)
                            .environmentObject(dataModel )
//                        }
                        
                        HStack {
                            Spacer()
                            UniversalText( RecallModel.ownerID, size: Constants.UISmallTextSize, font: Constants.mainFont  )
                                .onTapGesture { print( RecallModel.ownerID ) }
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, Constants.UIBottomOfPagePadding)
                    .onChange(of: page) { newValue in
                        if newValue == .data {
                            hide = false
                        } else {
                            hide = true
                        }
                    }
                }
            }
        }
        .padding(7)
        .universalBackground()
    }
}
