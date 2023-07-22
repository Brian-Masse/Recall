//
//  CalendarView.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift


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
    
    struct TabBar: View {
        
        struct TabBarIcon: View {
            
            @Binding var selection: MainView.MainPage
            
            let page: MainView.MainPage
            let title: String
            let icon: String
        
            var body: some View {
                VStack {
                    Image(systemName: icon)
                    UniversalText( title, size: Constants.UIDefaultTextSize )
                }
                .padding(5)
                .onTapGesture { selection = page }
                .background( selection == page ? .blue : .clear )
                .cornerRadius( selection == page ? Constants.UIDefaultCornerRadius : 0 )
            }
        }
        
        @Binding var pageSelection: MainView.MainPage
        
        var body: some View {
            HStack {
                
                Spacer()
                TabBarIcon(selection: $pageSelection, page: .calendar, title: "Calendar", icon: "calendar")
                Spacer()
                TabBarIcon(selection: $pageSelection, page: .goals, title: "Goals", icon: "checkmark.seal")
                Spacer()
                TabBarIcon(selection: $pageSelection, page: .categories, title: "Categories", icon: "wallet.pass")
                Spacer()
                TabBarIcon(selection: $pageSelection, page: .data, title: "Data", icon: "chart.bar")
                Spacer()
            }
            .padding(7)
            .universalTextStyle()
            .rectangularBackgorund(rounded: true)
            .shadow(radius: 5)
            .padding(.bottom)
            .padding()
        }
    }
    
    @ObservedResults( RecallCalendarEvent.self ) var events
    
    @State var currentPage: MainPage = .calendar
    
    var body: some View {
    
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                CalendarPageView().tag( MainPage.calendar )
                GoalsPageView(events: Array(events) ).tag( MainPage.goals )
                CategoriesPageView(events: Array(events) ).tag( MainPage.categories )
            }
            
            TabBar(pageSelection: $currentPage)
            
        }
        .ignoresSafeArea()
        .universalBackground()
        
        
    }
}
