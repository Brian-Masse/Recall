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
    
    var body: some View {
        
        VStack(alignment: .leading) {

            HStack {
                UniversalText( "Today's Recall", size: Constants.UITitleTextSize, font: Constants.titleFont, true )
                LargeRoundedButton("Add Event", icon: "arrow.up") { showingCreateEventView = true }
            }
            UniversalText( Date.now.formatted(date: .abbreviated, time: .omitted), size: Constants.UIDefaultTextSize, font: Constants.mainFont, lighter: true )
                .padding(.bottom)
        
            GeometryReader { geo in
                CalendarContainer(with: Array(components), from: 0, to: 24, geo: geo)
            }
    
            
        }
        .padding()
        .sheet(isPresented: $showingCreateEventView) { CalendarEventCreationView() }
        .universalBackground()
        
    }
    
}
