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
        
        HeadedBackground {
            HStack {
                UniversalText(title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont, true)
                Spacer()
            }
            
        } content: {
            VStack {
                ForEach(tags) { category in
                    TagPreviewView(tag: category, events: events)
                    
                    Rectangle()
                        .universalTextStyle()
                        .opacity(0.5)
                        .frame(height: 1)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
    }
    
    @Environment(\.colorScheme) var colorScheme
    
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
            }.padding(7)
            
            ScrollView(.vertical) {
                makeTagList(from: favorites, title: "Favorite Tags")
                    .padding(.bottom)
                
                makeTagList(from: nonFavorites, title: "All Tags")
                    .padding(.bottom)
                
            }
            
        }
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
