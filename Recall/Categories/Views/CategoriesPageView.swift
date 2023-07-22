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
    
    let events: [RecallCalendarEvent] 
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack {
                UniversalText( "Tags", size: Constants.UITitleTextSize, font: Constants.titleFont, true )
                Spacer()
                LargeRoundedButton("Create Tag", icon: "arrow.up") { showingCreateTagView = true }
            }.padding(7)
            
            ScrollView(.vertical) {
                
                HeadedBackground {
                    HStack {
                        UniversalText("Favorite Tags", size: Constants.UISubHeaderTextSize, font: Constants.titleFont, true)
                        Spacer()
                    }
                    
                } content: {
                    VStack {
                        ForEach(categories) { category in
                            TagPreviewView(tag: category, events: events)
                            
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
            CategoryCreationView(editing: false,
                                 tag: nil,
                                 label: "",
                                 goalRatings: Dictionary(),
                                 color: Colors.tint)
        }
        
    }
    
}
