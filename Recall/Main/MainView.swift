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
    
    //    MARK: Tabbar
    struct TabBar: View {
        struct TabBarIcon: View {
            
            @Binding var selection: MainView.MainPage
            
            let namespace: Namespace.ID
            
            let page: MainView.MainPage
            let title: String
            let icon: String
            
            @ViewBuilder private func makeIcon() -> some View {
                Image(systemName: icon)
            }
            
            var body: some View {
                Group {
                    if selection == page {
                        makeIcon()
                            .foregroundColor(.black)
                            .padding(.horizontal, 37)
                            .background {
                                Rectangle()
                                    .universalStyledBackgrond(.accent, onForeground: true)
                                    .cornerRadius(70)
                                    .frame(width: 90, height: 90)
                                    .matchedGeometryEffect(id: "highlight", in: namespace)
                            }
                        
                    } else {
                        makeIcon()
                            .padding(.horizontal, 7)
                    }
                }
                .onTapGesture { withAnimation { selection = page }}
            }
        }
        
        @Namespace private var tabBarNamespace
        @Binding var pageSelection: MainView.MainPage
        
        var body: some View {
            HStack(spacing: 10) {
                TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .calendar, title: "Recall", icon: "calendar")
                    .padding(.leading, pageSelection == .calendar ? 0 : 10 )
                TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .goals, title: "Goals", icon: "flag.checkered")
                TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .categories, title: "Tags", icon: "tag")
                TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .data, title: "Data", icon: "chart.bar")
                    .padding(.trailing, pageSelection == .data ? 0 : 10 )
            }
            .padding(7)
            .frame(height: 104)
            .ignoresSafeArea()
            .universalTextStyle()
            .background(.thinMaterial)
            .foregroundStyle(.ultraThickMaterial)
            .cornerRadius(55)
            .shadow(radius: 5)
            .padding(.bottom, 43)
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
    @Binding var appPage: RecallView.RecallPage
    @State var currentDay: Date = .now
    
    @State private var showingHalfPage: Bool = false
    
    @State var canDrag = false
    
    @State var uiTabarController: UITabBarController?
    
    //    MARK: Body
    var body: some View {
        
        let arrEvents = Array(events)
        let arrGoals = Array(goals)
        let arrTags = Array(tags)
    
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                NavigationView {
                    TabView(selection: $currentPage) {
                        CalendarPageView(events: arrEvents, appPage: $appPage)
                            .halfPageScreenReceiver(showing: $showingHalfPage)
                            .tag( MainPage.calendar )
                        
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
                }
                
                if !showingHalfPage { TabBar(pageSelection: $currentPage) }
                
                UpdateView()
            }
        }
        .task {
            Constants.setupConstants()
            RecallModel.dataModel.storeData( events: arrEvents, goals: arrGoals )
        }
        .onChange(of: events) { nEvents in RecallModel.dataModel.storeData( events: Array(nEvents)) }
        

        .universalBackground()
    }
}
