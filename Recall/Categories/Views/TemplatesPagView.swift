//
//  TemplatesPagView.swift
//  Recall
//
//  Created by Brian Masse on 11/8/23.
//

import Foundation
import SwiftUI

struct TemplatePageView: View {

//    MARK: Wrapper
    private struct Wrapper: View {
        let events: [RecallCalendarEvent]
        let template: RecallCalendarEvent
        
        @State var showingEditingScreen: Bool = false
        @State var showingDeletionAlert: Bool = false
        
        var body: some View {
            GeometryReader { geo in
                CalendarEventPreviewContentView(event: template, events: events, width: geo.size.width, height: 80)
                    .contextMenu {
                        Button { showingEditingScreen = true }  label:          { Label("edit", systemImage: "slider.horizontal.below.rectangle") }
                        Button(role: .destructive) { showingDeletionAlert = true } label:    { Label("delete", systemImage: "trash") }
                    }
                    .sheet(isPresented: $showingEditingScreen) {
                        CalendarEventCreationView.makeEventCreationView(currentDay: template.startTime, editing: true, event: template)
                    }
            }
            .frame(height: 80)
            
            .alert("Delete Associated Calendar Event?", isPresented: $showingDeletionAlert) {
                Button(role: .cancel) { showingDeletionAlert = false } label:    { Text("cancel") }
                Button(role: .destructive) { template.toggleTemplate() } label:    { Text("only delete template") }
                Button(role: .destructive) { template.delete() } label:    { Text("delete template and event") }
            } message: {
                Text("Choosing to delete both template and event permanently deletes the calendar event that constructed this template. Choosing to only delete the template keeps the original event in your recall log.")
            }
        }
    }
    
    let events: [RecallCalendarEvent]
    
//    MARK: Body
    var body: some View {
        let templates = RecallModel.getTemplates(from: events)
        
        if templates.count != 0 {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    ForEach( templates ) { template in
                        Wrapper(events: events, template: template)
                    }
                }
                .opaqueRectangularBackground(7, stroke: true)
                .padding(.bottom, Constants.UIBottomOfPagePadding)
                .padding(.top)
            }
        } else {
            VStack {
                UniversalText(Constants.templatesSplashPurpose,
                              size: Constants.UIDefaultTextSize,
                              font: Constants.mainFont)
                
                Spacer()
            }
        }
    }
}
