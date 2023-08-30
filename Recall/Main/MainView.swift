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
    
    enum MainPage: Int, Identifiable {
        case calendar
        case goals
        case data
        case categories
        case templates
        
        var id: Int {
            self.rawValue
        }
    }
    
//    MARK: Tabbar
    struct TabBar: View {
        
        @Environment(\.colorScheme) var colorScheme
        
        struct TabBarIcon: View {
            
            @Binding var selection: MainView.MainPage
            
            let namespace: Namespace.ID
            
            let page: MainView.MainPage
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
    
//    MARK: Body
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedResults( RecallCalendarEvent.self, where: { event in event.startTime > RecallModel.getEarliestEventDate() } ) var events
    @ObservedResults( RecallGoal.self ) var goals
    
    @State var currentPage: MainPage = .calendar
    @State var shouldRefreshData: Bool = false
    @Binding var appPage: ContentView.EntryPage
    
    private func refreshData(events: [RecallCalendarEvent]? = nil, goals: [RecallGoal]? = nil) async {
        await RecallModel.dataModel.updateProperties(events: events ?? nil, goals: goals ?? nil)
    }
    
    var body: some View {
    
        let arrEvents = Array(events)
        
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                CalendarPageView(events: arrEvents, appPage: $appPage)                              .tag( MainPage.calendar )
                GoalsPageView(events: arrEvents )           .tag( MainPage.goals )
                CategoriesPageView(events: arrEvents )      .tag( MainPage.categories )
                DataPageView(events: arrEvents)                                  .tag( MainPage.data )
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            TabBar(pageSelection: $currentPage)
            
        }
        
        .onAppear {
            Task { await refreshData(events: Array(events), goals: Array(goals)) }
            RecallModel.shared.setTint(from: colorScheme)
        }
        .onChange(of: events)   { newValue in Task { await refreshData(events: Array(newValue), goals: Array(goals)) } }
        
        .onChange(of: colorScheme) { newValue in
            RecallModel.shared.setTint(from: newValue)
        }
        
        
        .ignoresSafeArea()
        .universalBackground()
        
        
    }
}
