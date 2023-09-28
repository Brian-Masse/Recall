//
//  CalendarView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift


//MARK: MainView
struct MainView: View {
    
    static let TabBarNodes: [TabBarNode] = [
        .init("Recall",  icon: "calendar",       page: .calendar),
        .init("Goals",   icon: "flag.checkered", page: .goals),
        .init("Tags",    icon: "tag",            page: .categories),
        .init("Data",    icon: "chart.bar",      page: .data)
    ]
    
    static let MacOSTabBarNodes: [TabBarNode] = [
        .init("Recall",     icon: "calendar",           page: .calendar),
        
        .init("Goals",      icon: "flag.checkered",     page: .goals),
        .init("High",       icon: "exclamationmark.3",  page: .calendar, indent: true),
        .init("medium",     icon: "exclamationmark.2",  page: .calendar, indent: true),
        .init("low",        icon: "exclamationmark",    page: .calendar, indent: true),
        
        .init("tags & templates",       icon: "tag",                page: .categories),
        .init("Tags",       icon: "tag",                page: .calendar, indent: true),
        .init("Templates",  icon: "airport.extreme",    page: .calendar, indent: true),
        
        .init("Data",       icon: "chart.bar",          page: .data),
        .init("overview",   icon: "lines.measurement.horizontal",   page: .calendar, indent: true),
        .init("events",     icon: "calendar.day.timeline.left",     page: .calendar, indent: true),
        .init("goals",      icon: "flag.checkered",                 page: .calendar, indent: true),
        
    ]
    
    
//    MARK: Tabbar
    struct TabBar: View {
        
        @Environment(\.colorScheme) var colorScheme
        
        struct TabBarIcon: View {
            
            @Binding var selection: MainPage
            
            let namespace: Namespace.ID
            
            let page: MainPage
            let title: String
            let icon: String
        
            @ViewBuilder private func makeIcon() -> some View {
                VStack {
                    Image(systemName: icon)
//                    ResizeableIcon(icon: icon, size: Constants.UIDefaultTextSize + 2)
//                    UniversalText( title, size: Constants.UISmallTextSize, font: Constants.mainFont, wrap: false )
                    
                }
            }
            
            var body: some View {
                Group {
                    if selection == page {
                        makeIcon()
                            .foregroundColor(.black)
                            .padding(.horizontal, 37)
                            .background {
                                Rectangle()
                                    .universalForegroundColor()
                                    .cornerRadius(70)
                                    .frame(width: 90, height: 90)
//                                    .aspectRatio(1, contentMode: .fill)
                                    .matchedGeometryEffect(id: "highlight", in: namespace)
                            }
                            .shadow(color: Colors.tint.opacity(0.3), radius: 10)
                        
                    } else {
                        makeIcon()
                            .padding(.horizontal, 7)
                    }
                }
                .onTapGesture { withAnimation { selection = page }}
            }
        }
        
        @Namespace private var tabBarNamespace
        @Binding var pageSelection: MainPage
        
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

//            .padding(.bottom, 18)
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
    
    private func refreshData(events: [RecallCalendarEvent]? = nil, goals: [RecallGoal]? = nil) async {
        await RecallModel.dataModel.updateProperties(events: events ?? nil, goals: goals ?? nil)
    }
    
    
    //    MARK: Body
    var body: some View {
    
        let arrEvents = Array(events)
        
        NavigationSplitView {
            
            MacOSSideBar(mainPage: $currentPage)
            
            
        } detail: {
            
            ZStack(alignment: .bottom) {
                TabView(selection: $currentPage) {
                    CalendarPageView(events: arrEvents, currentDay: $currentDay, appPage: $appPage)      .tag( MainPage.calendar )
                    GoalsPageView(events: arrEvents )                           .tag( MainPage.goals )
                    CategoriesPageView(events: arrEvents )                      .tag( MainPage.categories )
                    DataPageView(events: arrEvents, page: $currentPage, currentDay: $currentDay)         .tag( MainPage.data )

                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                TabBar(pageSelection: $currentPage)
                
            }
            
            .onAppear {
                Task { await refreshData(events: Array(events), goals: Array(goals)) }
                RecallModel.shared.setTint(from: colorScheme)
                Constants.setupConstants()
            }
            .onChange(of: events)   { newValue in Task { await refreshData(events: Array(newValue), goals: Array(goals)) } }
            
            .onChange(of: colorScheme) { newValue in
                RecallModel.shared.setTint(from: newValue)
            }
            
            
        }
        .ignoresSafeArea()
        .universalBackground()
        
        
    }
}
