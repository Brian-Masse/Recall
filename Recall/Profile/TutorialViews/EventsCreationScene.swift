//
//  EventsCreationScene.swift
//  Recall
//
//  Created by Brian Masse on 8/29/23.
//

import Foundation
import SwiftUI
import RealmSwift


extension TutorialViews {

    struct EventsCreationScene: View {
        
//        MARK: Vars
        @ObservedResults(RecallGoal.self) var goals
        @ObservedResults(RecallCategory.self) var tags
        @ObservedResults(RecallCalendarEvent.self) var events
        
        @State var showingTagCreationView: Bool = false

        @Binding var scene: TutorialViews.TutorialScene
        @Binding var broadScene: TutorialViews.TutorialScene.BroadScene
        @Binding var nextButtonIsActive: Bool
        
//        private func hasGoalRating(at key: String) -> Bool {
//            goalRatings[key] != nil && goalRatings[key] != "" && goalRatings[key] != "0"
//        }
    
//        MARK: ViewBuilders

        @ViewBuilder
        private func makeSplashScreen() -> some View {
            Group {
                UniversalText("Recall your first day",
                              size: Constants.UITitleTextSize,
                              font: Constants.titleFont)
                .padding(.bottom)
                
                UniversalText( "Recalls can be any activity, as small as walking your dog, and as large as a week-long backpacking trip. Your tags then help categorize these events while goals help you track them.",
                               size: Constants.UISubHeaderTextSize,
                               font: Constants.mainFont)
                .padding(.trailing, 20)
            }
            .slideTransition()
            .onAppear { nextButtonIsActive = true }
        }
        

//        MARK: Body        
        var body: some View {
            
            VStack(alignment: .leading) {
                
                switch scene {
                case .eventCreation:  makeSplashScreen()
//                case .tagName:      makeNameView()
//                case .tagColor:     makeColorView()
//                case .tagGoal:      makeGoalsPicker()
//                case .tagView:      makeTagsView()
                    
                default: EmptyView()
                    
                }
            }
        }
    }
}


