//
//  TagsPageView.swift
//  Recall
//
//  Created by Brian Masse on 11/8/23.
//

import Foundation
import SwiftUI

struct TagPageView: View {

//    MARK: ViewBuilders
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
           .rectangularBackground(style: .primary, stroke: true)
       }
       .padding(.bottom)
   }
    
    let tags: [RecallCategory]
    let events: [RecallCalendarEvent]
    
//    MARK: Body
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
                .padding(.top)
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
