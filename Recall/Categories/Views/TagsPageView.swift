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
        
        @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
        
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
                    RecallIcon("tag.fill")
                        .foregroundStyle(tag.getColor())
                    
                    UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 5)
            .rectangularBackground(7, style: .secondary)
            .contextMenu {
                ContextMenuButton("edit", icon: "slider.horizontal.below.rectangle") {
                    coordinator.presentSheet(.tagCreationView(editting: true, tag: tag))
                }
                
                ContextMenuButton( tag.isFavorite ? "unfavorite" : "favorite", icon: tag.isFavorite ? "xmark" : "checkmark") {
                    tag.toggleFavorite()
                }
                
                ContextMenuButton("delete", icon: "trash", role: .destructive) {
                    tag.delete()
                }
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
       LazyVStack(alignment: .leading, spacing: 5) {
           UniversalText(title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
           
           if !tags.isEmpty {
               LazyVStack(alignment: .leading) {
                   ForEach(tags) { tag in
                       
                       TagPreviewView(tag: tag)
                   }
               }
               .rectangularBackground(7, style: .primary, stroke: true)
           } else {
               
               makeSectionFiller(icon: "tag.slash.fill",
                                 message: "No Favorite Tags. Tap and hold on one of your tags to favorite it.") { }
           }
       }
       .padding(.bottom)
   }
    
//    MARK: Vars
    let tags: [RecallCategory]
    
    @State var favoriteTags: [RecallCategory] = []
    @State var nonFavoriteTags: [RecallCategory] = []
    
    @State var scrollViewPosition: CGPoint = .zero
    
    func filterTags() async {
        let favoriteTags = await makeFavoriteTags()
        let nonFavoriteTags = await makeNonFavoriteTags()
        
        withAnimation {
            self.favoriteTags = favoriteTags
            self.nonFavoriteTags = nonFavoriteTags
        }
    }
    
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
            .task { await filterTags() }
            .onChange(of: tags) { Task { await filterTags() } }
        }
    }
}
