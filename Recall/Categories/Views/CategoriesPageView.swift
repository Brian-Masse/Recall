//
//  CategoriesPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct CategoriesPageView: View {
    
//    MARK: Page Picker
    @ViewBuilder
    private func makePagePickerOption(page: TagPage) -> some View {
        HStack {
            Spacer()
            Image(systemName: "arrow.up.right")
            UniversalText( page.rawValue, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            Spacer()
        }
        .if( activePage == page ) { view in view.tintRectangularBackground() }
        .if( activePage != page ) { view in view.secondaryOpaqueRectangularBackground() }
        .onTapGesture {
            withAnimation { activePage = page
            }
        }
    }
    
    @ViewBuilder
    private func makePagePicker() -> some View {
        HStack {
            makePagePickerOption(page: .tags)
            makePagePickerOption(page: .templates)
        }.padding(.bottom, 5)
    }
    
    enum TagPage: String, Identifiable, CaseIterable {
        case tags = "Tags"
        case templates = "Templates"
        
        var id: String { self.rawValue }
    }
    
//      MARK: TagPage
    struct TagTab: View {
    
       @ViewBuilder
       private func makeTagList(from tags: [RecallCategory], title: String) -> some View {
           
           VStack(alignment: .leading) {
               UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
               
               VStack {
                   ForEach(tags) { tag in
                       TagPreviewView(tag: tag, events: events)
                       
                       if tag.label != tags.last?.label ?? "" {
                           Rectangle()
                               .universalTextStyle()
                               .opacity(0.5)
                               .frame(height: 1)
                       }
                   }
               }
               .opaqueRectangularBackground(stroke: true)
           }
           .padding(.bottom)
       }
        
        let tags: [RecallCategory]
        let events: [RecallCalendarEvent]
        
        var body: some View {
            let favorites = Array(tags.filter { tag in tag.isFavorite })
            let nonFavorites = Array(tags.filter { tag in !tag.isFavorite })
            
            if tags.count != 0 {
                ScrollView(.vertical) {
                    VStack {
                        if favorites.count != 0 {
                            makeTagList(from: favorites, title: "Favorite Tags")
                                .padding(.bottom)
                        }
                        
                        if nonFavorites.count != 0 {
                            makeTagList(from: nonFavorites, title: "All Tags")
                                .padding(.bottom)
                                .padding(.bottom, Constants.UIBottomOfPagePadding)
                        }
                    }
                }
            } else {
                VStack {
                    UniversalText( Constants.tagSplashPurpose,
                                   size: Constants.UIDefaultTextSize,
                                   font: Constants.mainFont)
                    
                    Spacer()
                }
            }
        }
    }
    
//    MARK: TemplatesPage
    private struct TemplatesTab: View {
        
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
        
    @Environment(\.colorScheme) var colorScheme
    @ObservedResults( RecallCategory.self ) var categories
    
    @State var showingCreateTagView: Bool = false
    @State var showingCreateEventView: Bool = false
    @State var activePage: TagPage = .tags
    
    let events: [RecallCalendarEvent] 
    
//MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                UniversalText( activePage == .tags ? "Tags" : "Templates", size: Constants.UITitleTextSize, font: Constants.titleFont, true, scale: true )
                Spacer()
                LargeRoundedButton(activePage == .tags ? "Create Tag" : "Template", icon: "arrow.up") {
                    if activePage == .tags { showingCreateTagView = true }
                    if activePage == .templates { showingCreateEventView = true }
                }
            }
                
            makePagePicker()
            
            TabView(selection: $activePage) {
                TagTab(tags: Array(categories), events: events).tag( TagPage.tags )
                TemplatesTab(events: events).tag( TagPage.templates )
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.top)
        }
        .padding(7)
        .universalBackground()
        .sheet(isPresented: $showingCreateTagView) {
            CategoryCreationView(editing: false,
                                 tag: nil,
                                 label: "",
                                 goalRatings: Dictionary(),
                                 color: Colors.tint)
        }
        .sheet(isPresented: $showingCreateEventView) {
            CalendarEventCreationView.makeEventCreationView(currentDay: .now, template: true)
        }
    }
    
}
