//
//  DataPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals


struct DataPageView: View {
    
    enum DataPage: String, Identifiable, CaseIterable {
        case Overview
        case Events
        case Goals
        
        var id: String { self.rawValue }
    }
    
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makePageSelector(page: DataPage, icon: String) -> some View {
        HStack {
            Spacer()
            VStack {
                Image(systemName: icon)
                    .padding(.bottom, 7)
                
                UniversalText( page.rawValue, size: Constants.UISmallTextSize, font: Constants.mainFont )
            }
            Spacer()
        }
        
        .if(page == currentPage) { view in
            view
                .foregroundStyle(.black)
                .rectangularBackground(style: .accent)
        }
        .if(page != currentPage) { view in view.rectangularBackground(style: .secondary) }
        .onTapGesture { withAnimation { currentPage = page } }
    }
    
    @ViewBuilder
    private func makePageSelectors() -> some View {
        HStack {
            makePageSelector(page: .Overview, icon: "chart.dots.scatter")
            makePageSelector(page: .Goals, icon: "flag.checkered")
            makePageSelector(page: .Events, icon: "viewfinder.rectangular")
        }
    }
    
//    MARK: Vars
    let events: [RecallCalendarEvent]
    let goals: [RecallGoal]
    let tags: [RecallCategory]
    
    @ObservedObject private var dataModel: RecallDataModel = RecallModel.dataModel
    
    @Binding var mainViewPage: MainView.MainPage
    @Binding var currentDay: Date
    @State var currentPage: DataPage = .Overview
    
//    MARK: Body
    var body: some View {
        
        let arrGoals = Array(goals)
        
        VStack(alignment: .leading) {
            
            UniversalText("Data", size: Constants.UITitleTextSize, font: Constants.titleFont)
                .padding([.top, .horizontal], 7)

            makePageSelectors()
                .padding(.horizontal, 7)
            
            TabView(selection: $currentPage) {
                OverviewDataSection(goals: arrGoals, currentDay: $currentDay, page: $mainViewPage)
                    .tag(DataPage.Overview)
                    .environmentObject(dataModel )
                    .padding(7)
                    .ignoresSafeArea()
                
                GoalsDataSection(goals: arrGoals)
                    .tag(DataPage.Goals)
                    .environmentObject(dataModel )
                    .padding(7)
                    .ignoresSafeArea()
                
                EventsDataSection(page: $mainViewPage, currentDay: $currentDay)
                    .tag(DataPage.Events)
                    .environmentObject(dataModel )
                    .padding(7)
                    .ignoresSafeArea()
                
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        .universalBackground()
    }
}
