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
    
    @State var dragging: Bool = false
    
    @State var showingCreateEventView: Bool = false
    @State var showingCreateCategoryView: Bool = false
    
    var body: some View {
        
        VStack {
            GeometryReader { geo2 in
                ScrollView {
                    CalendarContainer(geo: geo2, events: Array( components), dragging: $dragging)
                }
                .scrollDisabled(dragging)
            }
            
            Spacer()
            
            HStack {
                ShortRoundedButton("Add Event", icon: "calendar.badge.plus") { showingCreateEventView = true }
                ShortRoundedButton( "Add Category", icon: "lanyardcard" ) { showingCreateCategoryView = true }
            }
        }
        .padding()
        
        .sheet(isPresented: $showingCreateEventView) { CalendarEventCreationView() }
        .sheet(isPresented: $showingCreateCategoryView) { CategoryCreationView() }
        
    }
    
}
