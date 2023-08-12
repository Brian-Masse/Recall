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
    
    enum MainPage: String, Identifiable {
        case calendar
        case goals
        case data
        case categories
        
        var id: String {
            self.rawValue
        }
    }
    
//    MARK: Tabbar
    struct TabBar: View {
        
        enum Edge {
            case left
            case right
            case none
        }
        
        struct TabBarIcon: View {
            
            @Binding var selection: MainView.MainPage
            
            let namespace: Namespace.ID
            
            let page: MainView.MainPage
            let title: String
            let icon: String
            let edge: TabBar.Edge
        
            var body: some View {
                Group {
                    if selection == page {
                        HStack {
                            ResizeableIcon(icon: "arrow.up", size: Constants.UISubHeaderTextSize)
                            UniversalText( title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, wrap: false )
                        }
                        .foregroundColor(.black)
                        .padding(34)
                        .background {
                            Rectangle()
                                .foregroundColor(Colors.tint)
                                .cornerRadius(50)
                                .matchedGeometryEffect(id: "highlight", in: namespace)
                        }
                        .shadow(color: Colors.tint.opacity(0.4), radius: 5)
                        
                    } else {
                        ResizeableIcon(icon: icon, size: Constants.UIDefaultTextSize)
                            .padding(.leading, edge == .left ? 30 : 0)
                            .padding(.trailing, edge == .right ? 30 : 0)
                    }
                }
                .onTapGesture { withAnimation { selection = page }}
            }
        }
        
        @Namespace private var tabBarNamespace
        @Binding var pageSelection: MainView.MainPage
        
        var body: some View {
            HStack(spacing: 10) {
                TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .calendar, title: "Recall", icon: "calendar", edge: .left)
                Spacer()
                TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .goals, title: "Goals", icon: "checkmark.seal", edge: .none)
                Spacer()
                TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .categories, title: "Tags", icon: "wallet.pass", edge: .none)
                Spacer()
                TabBarIcon(selection: $pageSelection, namespace: tabBarNamespace, page: .data, title: "Data", icon: "chart.bar", edge: .right)
            }
            .padding(7)
//            .padding(.vertical, 8)
            .padding(.bottom, 18)
            .ignoresSafeArea()
            .universalTextStyle()
            .background(.thinMaterial)
            .foregroundStyle(.ultraThickMaterial)
            .cornerRadius(57, corners: [.topLeft, .topRight])
            .shadow(radius: 5)
        }
    }
    
//    MARK: Body
    @ObservedResults( RecallCalendarEvent.self ) var events
    @ObservedResults( RecallGoal.self ) var goals
    
    @State var currentPage: MainPage = .calendar
    @State var shouldRefreshData: Bool = false
    
    private func refreshData(events: [RecallCalendarEvent]? = nil, goals: [RecallGoal]? = nil) async {
        await RecallModel.dataModel.updateProperties(events: events ?? nil, goals: goals ?? nil)
    }
    
    var body: some View {
    
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                CalendarPageView().tag( MainPage.calendar )
                GoalsPageView(events: Array(events) ).tag( MainPage.goals )
                CategoriesPageView(events: Array(events) ).tag( MainPage.categories )
                DataPageView().tag( MainPage.data )
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            TabBar(pageSelection: $currentPage)
            
        }
        
        .onAppear               { Task { await refreshData(events: Array(events), goals: Array(goals)) } }
        .onChange(of: events)   { newValue in Task { await refreshData(events: Array(newValue), goals: Array(goals)) } }
//        .onChange(of: goals)    { newValue in Task { await refreshData(goals: Array(newValue)) } }
        
        .ignoresSafeArea()
        .universalBackground()
        
        
    }
}
