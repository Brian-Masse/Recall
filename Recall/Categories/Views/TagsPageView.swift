//
//  TagsPageView.swift
//  Recall
//
//  Created by Brian Masse on 11/8/23.
//

import Foundation
import SwiftUI
import UIUniversals

struct TagPageView: View {

    private func makeFavoriteTags() async -> [RecallCategory] {
        Array(tags).filter { tag in tag.isFavorite }
    }
    
    private func makeNonFavoriteTags() async -> [RecallCategory] {
        Array(tags).filter { tag in !tag.isFavorite }
    }
    
//    MARK: ViewBuilders
   @ViewBuilder
   private func makeTagList(from tags: [RecallCategory], title: String) -> some View {
       if tags.count != 0 {
           LazyVStack(alignment: .leading) {
               UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont)
               
               LazyVStack(alignment: .leading) {
                   ForEach(tags) { tag in
                       
                       TagPreviewView(tag: tag, events: events)
                       
                       if tag.label != tags.last?.label ?? "" {
                           Divider()
                       }
                   }
               }
               .rectangularBackground(style: .primary, stroke: true)
           }
           .padding(.bottom)
       }
   }
    
    let tags: [RecallCategory]
    let events: [RecallCalendarEvent]
    
    @State var favoriteTags: [RecallCategory] = []
    @State var nonFavoriteTags: [RecallCategory] = []
    
//    MARK: Body
    var body: some View {
        
        if tags.count != 0 {
            ScrollView(.vertical) {
                
                LazyVStack(alignment: .leading) {
                    ForEach(tags) { tag in
                        TagPreviewView(tag: tag, events: events)
                    }
                }
                
//                makeTagList(from: favoriteTags, title: "Favorite Tags")
//                    .padding(.vertical)
//                
//                makeTagList(from: nonFavoriteTags, title: "All Tags")
//                    .padding(.bottom, Constants.UIBottomOfPagePadding)
                
            }.task {
                favoriteTags = await makeFavoriteTags()
                nonFavoriteTags = await makeNonFavoriteTags()
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
