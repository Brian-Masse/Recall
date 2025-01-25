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
        case favorites = "Favorites"
        
        var id: String { self.rawValue }

//        This is the name on the button that displays next to the page title
        func getAddButtonName() -> String {
            switch self {
            case .tags: return "Create Tag"
            case .favorites: return "Favorite"
            }
        }
    }
    
//    MARK: Vars
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
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
                UniversalText( page.rawValue, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                    .opacity(0.75)
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
                    if activePage == .tags { coordinator.presentSheet( .tagCreationView(editting: false) ) }
                    if activePage == .favorites { coordinator.presentSheet( .eventCreationView(favorite: true)) }
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
    }
}
