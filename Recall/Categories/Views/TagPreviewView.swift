//
//  TagPreviewView.swift
//  Recall
//
//  Created by Brian Masse on 7/21/23.
//

import Foundation
import SwiftUI
import RealmSwift

struct TagPreviewView: View {
    
    struct GoalTag: View {
        @State var showingGoalView: Bool = false
        
        let events: [RecallCalendarEvent]
        let goal: RecallGoal
        
        var body: some View {
            HStack {
                Image( systemName: "arrow.up.forward" )
                UniversalText( goal.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            }
            .secondaryOpaqueRectangularBackground()
            .onTapGesture { showingGoalView = true }
            .tag(goal.getEncryptionKey())
            .fullScreenCover(isPresented: $showingGoalView) {
                GoalView(goal: goal, events: events)
            }
        }
    }
    
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
            
            HStack {
                ForEach( tag.goalRatings ) { node in
                    if Int(node.data) ?? 0 != 0 {
                        if let goal = RecallGoal.getGoalFromKey( node.key ) {
                            GoalTag(events: events, goal: goal)
                        }
                    }
                }
                Spacer()
            }.padding(.leading)
            
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
