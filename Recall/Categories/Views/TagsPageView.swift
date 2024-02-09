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
           LazyVStack(alignment: .leading, spacing: 5) {
               UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont)
               
               LazyVStack(alignment: .leading) {
                   ForEach(tags) { tag in
                       
                       TagPreviewView(tag: tag)
                   }
               }
               .rectangularBackground(7, style: .primary, stroke: true)
           }
           .padding(.bottom)
       }
   }
    
    let tags: [RecallCategory]
    let events: [RecallCalendarEvent]
    
    @State var favoriteTags: [RecallCategory] = []
    @State var nonFavoriteTags: [RecallCategory] = []
    
    @State var scrollViewPosition: CGPoint = .zero
    
//    MARK: Body
    var body: some View {
        VStack {
            if tags.count != 0 {
                BlurScroll(10, blurHeight: 0.5, scrollPositionBinding: $scrollViewPosition) {
                    VStack {
                        makeTagList(from: favoriteTags, title: "Favorite Tags")
                            .padding(.vertical)
                        
                        makeTagList(from: nonFavoriteTags, title: "All Tags")
                            .padding(.bottom, Constants.UIBottomOfPagePadding)
                    }
                }
                .task {
                    favoriteTags = await makeFavoriteTags()
                    nonFavoriteTags = await makeNonFavoriteTags()
                }
            } else {
                UniversalText( Constants.tagSplashPurpose,
                               size: Constants.UIDefaultTextSize,
                               font: Constants.mainFont)
                
                Spacer()
            }
            
            Spacer()
        }
    }
}
