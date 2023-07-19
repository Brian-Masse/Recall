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
    
    @ObservedResults( RecallCalendarEvent.self ) var components
    
    @State var name: String = "name"
    @State var dragging: Bool = false
    
    @State var showingCreateEventView: Bool = false
    @State var showingCreateCategoryView: Bool = false
    
    var body: some View {
        
        GeometryReader { geo in
                
            VStack {
                GeometryReader { geo2 in
                    ScrollView {
                        CalendarContainer(geo: geo2, components: Array( components), dragging: $dragging)
                    }
                    .scrollDisabled(dragging)
                    .frame(height: geo.size.height)
                }
                
                HStack {
                    ShortRoundedButton("Add Event", icon: "calendar.badge.plus") { showingCreateEventView = true }
                    ShortRoundedButton( "Add Category", icon: "lanyardcard" ) { showingCreateCategoryView = true }
                }
            }
            
        }
        .sheet(isPresented: $showingCreateEventView) { CalendarEventCreationView() }
        .sheet(isPresented: $showingCreateCategoryView) { CategoryCreationView() }
        .universalBackground()
    }
}
