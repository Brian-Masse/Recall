//
//  CalendarView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

//MARK: MainView
struct MainView: View {
    
//    These are the pages in the main part of the app
    enum MainPage: Int, Identifiable {
        case calendar
        case goals
        case categories
        case data
        
        var id: Int {
            self.rawValue
        }
    }

    
    
    //    MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedResults( RecallCalendarEvent.self,
                      where: { event in event.startTime > RecallModel.getEarliestEventDate() && event.ownerID == RecallModel.ownerID } ) var events
    @ObservedResults( RecallGoal.self,
                      where: { goal in goal.ownerID == RecallModel.ownerID } ) var goals
    @ObservedResults( RecallCategory.self,
                      where: { tag in tag.ownerID == RecallModel.ownerID } ) var tags
    
    @State var currentPage: MainPage = .calendar
    @State var shouldRefreshData: Bool = false
    @State var currentDay: Date = .now
    
    @State private var showingHalfPage: Bool = false
    
    @State var canDrag = false
    
    @State var uiTabarController: UITabBarController?
    
    //    MARK: Body
    @State private var location: LocationResult? = nil
    
    var body: some View {
        
        let arrEvents = Array(events)
        let arrGoals = Array(goals)
        let arrTags = Array(tags)
    
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                TabView(selection: $currentPage) {
                    
                    StyledLocationPicker($location, title: "test")
//                    CalendarPageView(events: arrEvents, goals: arrGoals)
//                        .halfPageScreenReceiver(showing: $showingHalfPage)
//                        .tag( MainPage.calendar )
                    
                    GoalsPageView(goals: arrGoals, events: arrEvents, tags: arrTags )
                        .tag( MainPage.goals )
                    
                    CategoriesPageView(events: arrEvents, categories: arrTags )
                        .tag( MainPage.categories )
                    
                    DataPageView(events: arrEvents,
                                 goals: arrGoals,
                                 tags: arrTags,
                                 mainViewPage: $currentPage,
                                 currentDay: $currentDay)
                    .tag( MainPage.data )
                }
                .animation(.easeInOut, value: currentPage)

                if !showingHalfPage {
                    TabBar(pageSelection: $currentPage)
                        .padding(.bottom, 55)
                }
                
                UpdateView()
            }
        }
        .task {
            Constants.setupConstants()
            RecallModel.dataModel.storeData( events: arrEvents, goals: arrGoals )
        }
        .onChange(of: events) { RecallModel.dataModel.storeData( events: Array(events)) }
        

        .universalBackground()
    }
}
