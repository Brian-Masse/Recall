//
//  TemplatesPagView.swift
//  Recall
//
//  Created by Brian Masse on 11/8/23.
//

import Foundation
import SwiftUI
import UIUniversals

struct TemplatePageView: View {

//    MARK: EventContentView
    private struct EventContentView: View {
        let events: [RecallCalendarEvent]
        let template: RecallCalendarEvent
        
        @State var showingEditingScreen: Bool = false
        @State var showingDeletionAlert: Bool = false
        
        var body: some View {
            GeometryReader { geo in
                CalendarEventPreviewContentView(event: template, events: events, width: geo.size.width, height: 120)
                    .contextMenu {
                        ContextMenuButton("edit", icon: "slider.horizontal.below.rectangle") {
                            showingEditingScreen = true
                        }
                        
                        ContextMenuButton("untemplate", icon: "viewfinder.rectangular") {
                            template.toggleTemplate()
                        }
                        
                        ContextMenuButton("delete", icon: "trash", role: .destructive) {
                            showingDeletionAlert = true
                        }
                        
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
    
//    MARK: Class Methods
    private func getTemplates(from events: [RecallCalendarEvent]) async  {
        self.templatesLoaded = false
        
        self.templates = events.filter { event in event.isTemplate }
        
        await RecallModel.wait(for: 0.2)
        
        withAnimation { self.templatesLoaded = true }
    }
    
    let events: [RecallCalendarEvent]
    
    @State var templatesLoaded: Bool = false
    @State var templates: [RecallCalendarEvent] = []
    
    @State var scrollPosition: CGPoint = .zero
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    if templatesLoaded {
                        if templates.count != 0 {
                            LazyVStack(alignment: .leading, spacing: 7) {
                                ForEach( templates ) { template in
                                    EventContentView(events: events, template: template)
                                }
                            }
                            .rectangularBackground(7, style: .primary, stroke: true)
                            .padding(.bottom, Constants.UIBottomOfPagePadding)
                        } else {
                            UniversalText(Constants.templatesSplashPurpose,
                                          size: Constants.UIDefaultTextSize,
                                          font: Constants.mainFont)
                        }
                    } else {
                        LoadingPageView(count: 3, height: 80)
                    }
                    Spacer()
                }
            }
        }
        .task { await getTemplates(from: events) }
        .onDisappear { self.templatesLoaded = false }
    }
}
