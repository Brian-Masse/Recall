//
//  TagsPageView.swift
//  Recall
//
//  Created by Brian Masse on 11/8/23.
//

import Foundation
import SwiftUI
import UIUniversals
import RealmSwift

struct TagPageView: View {

    //MARK: TagPreviewView
    struct TagPreviewView: View {
        
        @ObservedRealmObject var tag: RecallCategory
        
        @State var showingEditTagView: Bool = false
        
        @ViewBuilder
        private func makeGoalTags() -> some View {
            WrappedHStack(collection: Array(tag.goalRatings)) { node in
                VStack {
                    if (Int(node.data) ?? 0) != 0 {
                        if let goal = RecallGoal.getGoalFromKey( node.key ) {
                            let multiplier = Int(node.data)!
                            
                            UniversalText( goal.label + " x\(multiplier)", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                                .rectangularBackground(10, style: .transparent)
                        }
                    }
                }
            }
        }
        
        var body: some View {
            VStack(spacing: 5) {
                HStack {
                    Image(systemName: "tag")
                        .foregroundStyle(tag.getColor())
                    
                    UniversalText(tag.label, size: Constants.UISubHeaderTextSize)
                    
                    Spacer()
                    
                    HStack {
                        UniversalText("Favorite", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                        Image(systemName: tag.isFavorite ? "checkmark" : "arrow.up")
                    }
                    .onTapGesture { withAnimation { tag.toggleFavorite() }}
                }
                
//                makeGoalTags()
//                    .padding(.leading, 25)
            }
            .padding(.vertical, 5)
            .rectangularBackground(7, style: .secondary)
            .contextMenu {
                ContextMenuButton("edit", icon: "slider.horizontal.below.rectangle") {
                    showingEditTagView = true
                }
                
                ContextMenuButton( tag.isFavorite ? "unfavorite" : "favorite", icon: tag.isFavorite ? "xmark" : "checkmark") {
                    tag.toggleFavorite()
                }
                
                ContextMenuButton("delete", icon: "trash", role: .destructive) {
                    tag.delete()
                }
            }
            .sheet(isPresented: $showingEditTagView) {
                CategoryCreationView(editing: true,
                                     tag: tag,
                                     label: tag.label,
                                     goalRatings: RecallCalendarEvent.translateGoalRatingList(tag.goalRatings),
                                     color: tag.getColor())
            }
        }
    }
    
//    MARK: Convenience Functions
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
    
//    MARK: Vars
    let tags: [RecallCategory]
    let events: [RecallCalendarEvent]
    
    @State var favoriteTags: [RecallCategory] = []
    @State var nonFavoriteTags: [RecallCategory] = []
    
    @State var scrollViewPosition: CGPoint = .zero
    
//    MARK: Body
    var body: some View {
        if tags.count != 0 {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    makeTagList(from: favoriteTags, title: "Favorite Tags")
                        .padding(.vertical, 5)
                    
                    makeTagList(from: nonFavoriteTags, title: "All Tags")
                }
                .padding(.bottom, Constants.UIBottomOfPagePadding)
            }
            .task {
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
