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
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedResults( RecallCategory.self ) var categories
    
    @State var showingCreateTagView: Bool = false
    @State var showingEditTagView: Bool = false
    @State var showingGoalView: Bool = false
    
    let events: [RecallCalendarEvent] 
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                UniversalText( "Tags", size: Constants.UITitleTextSize, font: Constants.titleFont, true )
                Spacer()
                LargeRoundedButton("Create Tag", icon: "arrow.up") { showingCreateTagView = true }
            }.padding()
            
            ScrollView(.vertical) {
                
                HeadedBackground {
                    HStack {
                        UniversalText("Favorite Tags", size: Constants.UISubHeaderTextSize, font: Constants.titleFont, true)
                        Spacer()
                    }
                    
                } content: {
                    VStack {
                        ForEach(categories) { category in
                            VStack {
                                HStack {
                                    Image(systemName: "tag")
                                    UniversalText(category.label, size: Constants.UISubHeaderTextSize, font: Constants.mainFont)
                                    
                                    Spacer()
                                    
                                    Circle()
                                        .frame(width: 15, height: 15)
                                        .foregroundColor(category.getColor())
                                }
                                
                                HStack {
                                    ForEach( category.goalRatings ) { node in
                                        if let goal = RecallGoal.getGoalFromKey( node.key ) {
                                            HStack {
                                                Image( systemName: "arrow.up.forward" )
                                                UniversalText( goal.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                                            }
                                            .secondaryOpaqueRectangularBackground()
                                            .onTapGesture { showingGoalView = true }
                                            .fullScreenCover(isPresented: $showingGoalView) {
                                                GoalView(goal: goal, events: events)
                                            }
                                        }
                                    }
                                    Spacer()
                                }.padding(.leading)
                                
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                            .background( colorScheme == .light ? .white : .black )
                            .contextMenu { Button("edit") { showingEditTagView = true } }
                            
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
            
        }
        .universalBackground()
        .sheet(isPresented: $showingCreateTagView) {
            CategoryCreationView()
        }
        
    }
    
}
