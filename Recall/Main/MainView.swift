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
                                //                                    .aspectRatio(1, contentMode: .fill)
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
    
    @ObservedResults( RecallCalendarEvent.self, where: { event in event.startTime > RecallModel.getEarliestEventDate() } ) var events
    @ObservedResults( RecallGoal.self ) var goals
    
    @State var currentPage: MainPage = .calendar
    @State var shouldRefreshData: Bool = false
    @Binding var appPage: ContentView.EntryPage
    @State var currentDay: Date = .now
    
    @State private var showingHalfPage: Bool = false
    
    private func refreshData(events: [RecallCalendarEvent]? = nil, goals: [RecallGoal]? = nil) async {
        await RecallModel.dataModel.updateProperties(events: events ?? nil, goals: goals ?? nil)
    }
    
    @State var canDrag = false
    
    @State var uiTabarController: UITabBarController?
    
    //    MARK: Body
    var body: some View {
        
        let arrEvents = Array(events)
        let arrGoals = Array(goals)
    
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                NavigationView {
                    TabView(selection: $currentPage) {
                        CalendarPageView(events: arrEvents, currentDay: $currentDay, appPage: $appPage)
                            .halfPageScreenReceiver(showing: $showingHalfPage)
                            .tag( MainPage.calendar )
                        
                        GoalsPageView(goals: arrGoals, events: arrEvents )
                            .tag( MainPage.goals )
    
                        CategoriesPageView(events: arrEvents )
                            .tag( MainPage.categories )
                    
                        Text("hi")
                            .tag( MainPage.data )
                    }
                }
                
                if !showingHalfPage { TabBar(pageSelection: $currentPage) }
                
                UpdateView()
            }
        }
        .onAppear {
            Task { await refreshData(events: Array(events), goals: Array(goals)) }
            Constants.setupConstants()
        }
        .onChange(of: events)   { newValue in Task { await refreshData(events: Array(newValue), goals: Array(goals)) } }
        .universalBackground()
    }
}
