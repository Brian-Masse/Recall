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
        .onTapGesture { withAnimation { activePage = page } }
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
    private struct TagTab: View {
    
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
            
            ScrollView(.vertical) {
                VStack {
                    makeTagList(from: favorites, title: "Favorite Tags")
                        .padding(.bottom)
                    
                    makeTagList(from: nonFavorites, title: "All Tags")
                        .padding(.bottom)
                        .padding(.bottom, Constants.UIBottomOfPagePadding)
                }
            }
        }
    }
    
//    MARK: TemplatesPage
    private struct TemplatesTab: View {
        let events: [RecallCalendarEvent]
        
        var body: some View {
            let templates = RecallModel.getTemplates(from: events)
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    ForEach( templates ) { template in
                        GeometryReader { geo in
                            CalendarEventPreviewContentView(event: template, events: events, width: geo.size.width, height: 80)
                        }
                        .frame(height: 80)
                        
                    }
                }
                .opaqueRectangularBackground(7, stroke: true)
                .padding(.bottom, Constants.UIBottomOfPagePadding)
            }
        }
    }
        
    @Environment(\.colorScheme) var colorScheme
    @ObservedResults( RecallCategory.self ) var categories
    
    @State var showingCreateTagView: Bool = false
    @State var activePage: TagPage = .tags
    
    let events: [RecallCalendarEvent] 
    
//MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                UniversalText( activePage == .tags ? "Tags" : "Templates", size: Constants.UITitleTextSize, font: Constants.titleFont, true, scale: true )
                Spacer()
                LargeRoundedButton(activePage == .tags ? "Create Tag" : "Template", icon: "arrow.up") { showingCreateTagView = true }
            }
                
            makePagePicker()
            
            TabView(selection: $activePage) {
                TagTab(tags: Array(categories), events: events).tag( TagPage.tags )
                TemplatesTab(events: events).tag( TagPage.templates )
            }.tabViewStyle(.page(indexDisplayMode: .never))
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
    }
    
}
