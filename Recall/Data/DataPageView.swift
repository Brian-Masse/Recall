//
//  DataPageView.swift
//  Recall
//
//  Created by Brian Masse on 7/31/23.
//

import Foundation
import SwiftUI
import RealmSwift


struct DataPageView: View {
    
    
    
    @ObservedResults( RecallCalendarEvent.self ) var events
    @ObservedResults( RecallCategory.self ) var tags
    
//    MARK: Body
    
    var body: some View {
        
        let arrEvents = Array(events)
//        let arrTags = Array(tags)
        
        VStack(alignment: .leading) {
            
            UniversalText("Data", size: Constants.UITitleTextSize, font: Constants.titleFont)
            
            ScrollView(.vertical) {
                
                
                
                VStack(alignment: .leading) {
                    
                    DataCollection("Events") {
                        ActivitiesPerDay("Number of Hours, by tag", with: arrEvents) { event in event.getLengthInHours() }

                        
                        
                    }
                
                 
                    Spacer()
                    
                }
            }
        }
        .padding(7)
        .universalColoredBackground(Colors.tint)
    }
}


struct DataCollection<Content: View>: View {
    
    let label: String
    let content: Content
    
    init( _ label: String, @ViewBuilder content: ()->Content ) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( label, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                .padding(.bottom)
            
            content
            
        }.opaqueRectangularBackground()
        
    }
    
}
