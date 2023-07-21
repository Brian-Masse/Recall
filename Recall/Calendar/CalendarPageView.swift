//
//  CalendarPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/19/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct CalendarPageView: View {
    
    
    @ObservedResults( RecallCalendarEvent.self ) var components
    
    
    @State var showingCreateEventView: Bool = false
    @State var showingCreateCategoryView: Bool = false
    
    var body: some View {
        
        VStack(alignment: .leading) {

            UniversalText( "Today's Recall", size: Constants.UITitleTextSize, true )
            UniversalText( Date.now.formatted(date: .abbreviated, time: .omitted), size: Constants.UIDefaultTextSize, lighter: true )
                .padding(.bottom)
            
            CalendarContainer(events: Array( components ))
            
            Spacer()
                
            HStack {
                ShortRoundedButton("Add Event", icon: "calendar.badge.plus") { showingCreateEventView = true }
                ShortRoundedButton( "Add Category", icon: "lanyardcard" ) { showingCreateCategoryView = true }
            }
        }
        .padding()
        .sheet(isPresented: $showingCreateEventView) { CalendarEventCreationView() }
        .sheet(isPresented: $showingCreateCategoryView) { CategoryCreationView() }
        .universalBackground()
        
    }
    
}
