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

//        This is the name on the button that displays next to the page title
        func getAddButtonName() -> String {
            switch self {
            case .tags: return "Create Tag"
            case .templates: return "Template"
            case .favorites: return "Favorite"
            }
        }
    }
    
//    MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    
    @State var showingCreateTagView: Bool = false
    @State var showingCreateEventView: Bool = false
    @State var showingCreateFavoriteEventView: Bool = false
    
    
    @State var activePage: TagPage = .tags
    
    let events: [RecallCalendarEvent]
    let categories: [RecallCategory]
    
//    MARK: Page Picker
    @ViewBuilder
    private func makePagePickerOption(page: TagPage, icon: String) -> some View {
        HStack {
            Spacer()
            VStack {
                RecallIcon(icon)
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
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader(_ geo: GeometryProxy) -> some View {
        Group {
            HStack {
                UniversalText( activePage.rawValue, size: Constants.UIHeaderTextSize, font: Constants.titleFont, scale: true )
                Spacer()
                
                IconButton("plus", label: activePage.getAddButtonName()) {
                    if activePage == .tags { showingCreateTagView = true }
                    if activePage == .templates { showingCreateEventView = true }
                    if activePage == .favorites { showingCreateFavoriteEventView = true }
                }
            }
            
            makePagePicker(geo: geo)
        }.padding(7)
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                
                makeHeader(geo)
                
                TabView( selection: $activePage ) {
                    TagPageView(tags: Array(categories))
                        .ignoresSafeArea()
                        .padding(.horizontal, 7)
                        .tag( TagPage.tags )
                    
                    TemplatePageView(events: events)
                        .ignoresSafeArea()
                        .padding(.horizontal, 7)
                        .tag( TagPage.templates )
                    
                    FavoritesPageView(events: events)
                        .ignoresSafeArea()
                        .padding(.horizontal, 7)
                        .tag( TagPage.favorites )
                }
                .ignoresSafeArea()
                .tabViewStyle(.page(indexDisplayMode: .never) )
            }
        }
        .universalBackground()
        .sheet(isPresented: $showingCreateTagView) {
            CategoryCreationView(editing: false,
                                 tag: nil,
                                 label: "",
                                 goalRatings: Dictionary())
        }
        .sheet(isPresented: $showingCreateEventView) {
            CalendarEventCreationView.makeEventCreationView(currentDay: .now, template: true)
        }
        .sheet(isPresented: $showingCreateFavoriteEventView) {
            CalendarEventCreationView.makeEventCreationView(currentDay: .now, favorite: true)
        }
    }
}
