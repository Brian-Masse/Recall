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

//    MARK: ViewBuilders
   @ViewBuilder
   private func makeTagList(from tags: [RecallCategory], title: String) -> some View {
       
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
    
    let tags: [RecallCategory]
    let events: [RecallCalendarEvent]
    
//    MARK: Body
    var body: some View {
//        let favorites = Array(tags.filter { tag in tag.isFavorite })
//        let nonFavorites = Array(tags.filter { tag in !tag.isFavorite })
        
        ScrollView(.vertical) {
            makeTagList(from: tags, title: "tags")
            
//            LazyVStack {
//                ForEach( tags ) { tag in
//                    
//                    TagPreviewView(tag: tag, events: events)
//                    
//                    //                UniversalText( tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
//                }
//            }
                .padding(.vertical)
        }
        
        
//        if tags.count != 0 {
//            ScrollView(.vertical) {
//                VStack {
//                    if favorites.count != 0 {
//                        makeTagList(from: favorites, title: "Favorite Tags")
//                            .padding(.bottom)
//                    }
//                    
//                    if nonFavorites.count != 0 {
//                        makeTagList(from: nonFavorites, title: "All Tags")
//                            .padding(.bottom)
//                            .padding(.bottom, Constants.UIBottomOfPagePadding)
//                    }
//                }
//                .padding(.top)
//            }
//        } else {
//            VStack {
//                UniversalText( Constants.tagSplashPurpose,
//                               size: Constants.UIDefaultTextSize,
//                               font: Constants.mainFont)
//                
//                Spacer()
//            }
//        }
    }
}
