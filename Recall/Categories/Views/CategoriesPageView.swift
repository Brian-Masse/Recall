//
//  CategoriesPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

struct CategoriesPageView: View {
    
    enum TagPage: String, Identifiable, CaseIterable {
        case tags = "Tags"
        case templates = "Templates"
        case favorites = "Favorites"
        
        var id: String { self.rawValue }

        func getAddButtonName() -> String {
            switch self {
            case .tags: return "Create Tag"
            case .templates: return "Template"
            case .favorites: return "Favorite"
            }
        }
    }
    
//    MARK: Page Picker
    @ViewBuilder
    private func makePagePickerOption(page: TagPage, icon: String) -> some View {
        HStack {
            Spacer()
            VStack {
                Image(systemName: icon)
                    .padding(.bottom, 5)
                UniversalText( page.rawValue, size: Constants.UIDefaultTextSize, font: Constants.mainFont, wrap: false, scale: true)
            }
            Spacer()
        }
        .if( activePage == page ) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
        .if( activePage != page ) { view in view.rectangularBackground(style: .secondary) }
        .onTapGesture { withAnimation { activePage = page }}
    }
    
    @ViewBuilder
    private func makePagePicker(geo: GeometryProxy) -> some View {
        HStack {
            makePagePickerOption(page: .tags, icon: "tag")
            makePagePickerOption(page: .templates, icon: "viewfinder.rectangular")
            makePagePickerOption(page: .favorites, icon: "circle.rectangle.filled.pattern.diagonalline")
        }
        .padding(.bottom, 5)
        .frame(height: geo.size.height / 10)
    }

        
//    MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    @ObservedResults( RecallCategory.self ) var categories
    
    @State var showingCreateTagView: Bool = false
    @State var showingCreateEventView: Bool = false
    @State var showingCreateFavoriteEventView: Bool = false
    
    
    @State var activePage: TagPage = .tags
    
    let events: [RecallCalendarEvent] 
    
//    MARK: Body
    var body: some View {
        
        GeometryReader { geo in
            VStack(alignment: .leading) {
                
                HStack {
                    UniversalText( activePage.rawValue, size: Constants.UITitleTextSize, font: Constants.titleFont, scale: true )
                    Spacer()
                
                    LargeRoundedButton(activePage.getAddButtonName(), icon: "arrow.up") {
                        if activePage == .tags { showingCreateTagView = true }
                        if activePage == .templates { showingCreateEventView = true }
                        if activePage == .favorites { showingCreateFavoriteEventView = true }
                    }
                }
                
                makePagePicker(geo: geo)
                
                TabView(selection: $activePage) {
                    TagPageView(tags: Array(categories), events: events).tag( TagPage.tags )
//                    TemplatePageView(events: events).tag( TagPage.templates )
//                    FavoritesPageView(events: events).tag( TagPage.favorites )
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .padding(7)
        .universalBackground()
        .sheet(isPresented: $showingCreateTagView) {
            CategoryCreationView(editing: false,
                                 tag: nil,
                                 label: "",
                                 goalRatings: Dictionary(),
                                 color: RecallModel.shared.activeColor)
        }
        .sheet(isPresented: $showingCreateEventView) {
            CalendarEventCreationView.makeEventCreationView(currentDay: .now, template: true)
        }
        .sheet(isPresented: $showingCreateFavoriteEventView) {
            CalendarEventCreationView.makeEventCreationView(currentDay: .now, favorite: true)
        }
    }
    
}
