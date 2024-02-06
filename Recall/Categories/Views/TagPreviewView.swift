//
//  TagPreviewView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

//MARK: GoalTags
struct GoalTags: View {
    
    struct GoalTag: View {
        @State var showingGoalView: Bool = false
        
        let events: [RecallCalendarEvent]
        let goal: RecallGoal
        let multiplier: Int
        
        var body: some View {
            UniversalText( goal.label + (multiplier <= 1 ? "" : " x\(multiplier)"), size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                .rectangularBackground(10, style: .transparent)
        }
    }
    
    let goalRatings: [GoalNode]
    let events: [RecallCalendarEvent]
    
    var body: some View {
        WrappedHStack(collection: goalRatings) { node in
            VStack {
                if Int(node.data) ?? 0 != 0 {
                    if let goal = RecallGoal.getGoalFromKey( node.key ) {
                        GoalTag(events: events, goal: goal, multiplier: Int(node.data)! )
                    }
                }
            }
        }
    }
    
}

//MARK: TagPreviewView
struct TagPreviewView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedRealmObject var tag: RecallCategory
    
    let events: [RecallCalendarEvent]
    
    @State var showingEditTagView: Bool = false
    
    @ViewBuilder
    private func makeFavoriteToggle() -> some View {
        Group {
            if tag.isFavorite {
                HStack {
                    UniversalText("Favorite", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                    Image(systemName: "checkmark")
                }
                
            } else {
                HStack {
                    UniversalText("Favorite", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                    Image(systemName: "arrow.up")
                }
            }
        }
        .onTapGesture { withAnimation { tag.toggleFavorite() }}
    }
    
    var body: some View {
        
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(tag.getColor())
                UniversalText(tag.label, size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                
                Spacer()
                
                makeFavoriteToggle()
            }
            
            GoalTags(goalRatings: Array(tag.goalRatings), events: events)
                .padding(.leading, 25)
            
        }
        .rectangularBackground(0, style: .primary, cornerRadius: 0)
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
