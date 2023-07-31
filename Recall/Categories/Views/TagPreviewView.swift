//
//  TagPreviewView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift

//MARK: GoalTags
struct GoalTags: View {
    
    struct GoalTag: View {
        @State var showingGoalView: Bool = false
        
        let events: [RecallCalendarEvent]
        let goal: RecallGoal
        let multiplier: Int
        
        var body: some View {
            HStack {
                Image( systemName: "arrow.up.forward" )
                UniversalText( goal.label + (multiplier <= 1 ? "" : " x\(multiplier)"), size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            }
            .secondaryOpaqueRectangularBackground()
            .onTapGesture { showingGoalView = true }
            .tag(goal.getEncryptionKey())
            .fullScreenCover(isPresented: $showingGoalView) {
                GoalView(goal: goal, events: events)
            }
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
        }.padding(.leading)
    }
    
}

//MARK: TagPreviewView
struct TagPreviewView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedRealmObject var tag: RecallCategory
    
    let events: [RecallCalendarEvent]
    
    @State var showingEditTagView: Bool = false
    
    var body: some View {
        
        VStack {
            HStack {
                Image(systemName: "tag")
                UniversalText(tag.label, size: Constants.UISubHeaderTextSize, font: Constants.mainFont)
                
                Spacer()
                
                Image(systemName: tag.isFavorite ? "checkmark.seal" : "seal")
                    .onTapGesture { tag.toggleFavorite() }
            }
            
            GoalTags(goalRatings: Array(tag.goalRatings), events: events)
            
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background( colorScheme == .light ? .white : .black )
        .contextMenu {
            Button("edit") { showingEditTagView = true }
            Button("delete") { tag.delete() }
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
