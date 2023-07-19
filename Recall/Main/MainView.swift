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
        
        var id: String {
            self.rawValue
        }
    }
    
    @State var currentPage: MainPage = .calendar
    
    
    var body: some View {
        
        GeometryReader { geo in
            
            TabView(selection: $currentPage) {
                CalendarPageView().tag( MainPage.calendar )
                GoalsPageView().tag( MainPage.goals )

            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            
        }
        .padding()
        .universalBackground(padding: false)
    }
}
