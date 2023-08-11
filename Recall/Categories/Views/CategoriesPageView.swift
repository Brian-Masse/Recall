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
    
    @ViewBuilder
    func makeTagList(from tags: [RecallCategory], title: String) -> some View {
        
        VStack(alignment: .leading) {
            UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
            
            VStack {
                ForEach(tags) { tag in
                    TagPreviewView(tag: tag, events: events)
                        .matchedGeometryEffect(id: tag.label, in: tagsPageNamespace)
                    
                    if tag.label != tags.last?.label ?? "" {
                        Rectangle()
                            .universalTextStyle()
                            .opacity(0.5)
                            .frame(height: 1)
                    }
                }
            }
            .opaqueRectangularBackground()
        }
        .padding(.bottom)
    }
    
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var tagsPageNamespace
    
    @ObservedResults( RecallCategory.self ) var categories
    
    @State var showingCreateTagView: Bool = false
    
    let events: [RecallCalendarEvent] 
    
    var body: some View {
        
        let favorites = Array(categories.filter { tag in tag.isFavorite })
        let nonFavorites = Array(categories.filter { tag in !tag.isFavorite })
        
        VStack(alignment: .leading) {
            
            HStack {
                UniversalText( "Tags", size: Constants.UITitleTextSize, font: Constants.titleFont, true )
                Spacer()
                LargeRoundedButton("Create Tag", icon: "arrow.up") { showingCreateTagView = true }
            }
            
            ScrollView(.vertical) {
                makeTagList(from: favorites, title: "Favorite Tags")
                    .padding(.bottom)
                
                makeTagList(from: nonFavorites, title: "All Tags")
                    .padding(.bottom)
                    .padding(.bottom, Constants.UIBottomOfPagePadding)
                
            }
            
        }
        .padding(7)
        .universalColoredBackground(Colors.tint)
        .sheet(isPresented: $showingCreateTagView) {
            CategoryCreationView(editing: false,
                                 tag: nil,
                                 label: "",
                                 goalRatings: Dictionary(),
                                 color: Colors.tint)
        }
    }
    
}
