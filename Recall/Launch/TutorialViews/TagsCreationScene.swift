//
//  TagsCreationScene.swift
//  Recall
//
//  Created by Brian Masse on 8/28/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

extension TutorialViews {

    struct TagsCreationScene: View {
        
//        MARK: Vars
        @ObservedResults(RecallGoal.self,
                         where: { goal in goal.ownerID == RecallModel.ownerID }) var goals
        @ObservedResults(RecallCategory.self,
                         where: { tag in tag.ownerID == RecallModel.ownerID }) var tags
        
        @State var showingTagCreationView: Bool = false
        @State var sentTag: Bool = false
        
        @State var name: String = ""
        @State var color: Color = Colors.defaultLightAccent
        @State var goalRatings: Dictionary<String, String> = Dictionary()
        

        @Binding var scene: TutorialViews.TutorialScene
        @Binding var broadScene: TutorialViews.TutorialScene.BroadScene
        @Binding var nextButtonIsActive: Bool
        
        private func hasGoalRating(at key: String) -> Bool {
            goalRatings[key] != nil && goalRatings[key] != "" && goalRatings[key] != "0"
        }
    
//        MARK: ViewBuilders

        @ViewBuilder
        private func makeSplashScreen() -> some View {
            Group {
                UniversalText("Create your first tag",
                              size: Constants.UITitleTextSize,
                              font: Constants.titleFont)
                .padding(.bottom)
                
                UniversalText( Constants.tagSplashPurpose,
                               size: Constants.UISubHeaderTextSize,
                               font: Constants.mainFont)
                .padding(.trailing, 20)
            }
            .slideTransition()
            .onAppear { nextButtonIsActive = true }
        }
        
//        MARK: Basic Info
        @ViewBuilder
        private func makeNameView() -> some View {
            VStack(alignment: .leading) {
                StyledTextField(title: "Whats the name of this tag?", binding: $name)
                    .onChange(of: name) { 
                        if name.isEmpty { return }
                        nextButtonIsActive = true
                    }
                
                Group {
                    UniversalText("ie. went for a walk", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                        .padding(.bottom, 5)
                    
                    UniversalText("ie. Hung out with friends", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                }
                .opacity(0.65)
                .padding(.leading)
            }
            .slideTransition()
        }
        
        @ViewBuilder
        private func makeColorView() -> some View {
            StyledColorPicker(label: "What color is this tag?", color: $color)
                .onAppear() { nextButtonIsActive = true }
                .slideTransition()
        }
        
//        MARK: GoalRatings
        @ViewBuilder
        private func makeGoalsPicker() -> some View {
            ScrollView {
                VStack(alignment: .leading) {
                    UniversalText( "What goals should this tag contribute to?",
                                   size: Constants.UIHeaderTextSize,
                                   font: Constants.titleFont ).padding(.bottom, 5)
                    UniversalText( "Any event marked with this tag will contribute to any of the goals you select.",
                                   size: Constants.UIDefaultTextSize,
                                   font: Constants.mainFont).padding(.bottom)
                    
                    WrappedHStack(collection: Array(goals)) { goal in
                        let key = goal.getEncryptionKey()
                        
                        HStack {
                            Image(systemName: "arrow.up.forward")
                            UniversalText(goal.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                        }
                        .if(!hasGoalRating(at: key)) { view in view.rectangularBackground(style: .secondary) }
                        .if(hasGoalRating(at: key)) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
                        .onTapGesture {
                            if goalRatings[key] == nil { goalRatings[key] = "1" }
                            else { goalRatings[key] = nil }
                        }
                    }.padding(.bottom)
                    
                    if goalRatings.count != 0 {
                        VStack(alignment: .leading) {
                            UniversalText( "How much should this tag contribute to those goals?",
                                           size: Constants.UIHeaderTextSize,
                                           font: Constants.titleFont ).padding(.bottom, 5)
                            UniversalText( "You can set custom multipliers for each goal to increase the amount the length of an event contributes to a certain goal.",
                                           size: Constants.UIDefaultTextSize,
                                           font: Constants.mainFont).padding(.bottom)
                            
                            ForEach(goals, id: \.key) { goal in
                                if Int(goalRatings[goal.key] ?? "0") ?? 0 != 0 {
                                    GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: false)
                                }
                            }
                        }
                    }
                }
            }
            .slideTransition()
            .onAppear() { nextButtonIsActive = true }
        }
        
//        MARK: TagsPage
        @ViewBuilder
        private func makeTagsView() -> some View {
            
            VStack(alignment: .leading) {
                TagPageView(tags: Array(tags))
                Spacer()
                LargeRoundedButton("create another tag", icon: "arrow.up", wide: true) {
                    showingTagCreationView = true
                }
            }
            .slideTransition()
            .onAppear() {
                nextButtonIsActive = true
                
                if sentTag { return }
                let tag = RecallCategory(ownerID: RecallModel.ownerID,
                                         label: name,
                                         goalRatings: goalRatings,
                                         color: color)
                RealmManager.addObject(tag)
                sentTag = true
            }
            .sheet(isPresented: $showingTagCreationView) {
                CategoryCreationView(editing: false,
                                     tag: nil,
                                     label: "",
                                     goalRatings: Dictionary())
            }
            
        }
        
//        MARK: Body
        
        var body: some View {
            
            VStack(alignment: .leading) {
                
                switch scene {
                case .tagCreation:  makeSplashScreen()
                case .tagName:      makeNameView()
                case .tagColor:     makeColorView()
                case .tagGoal:      makeGoalsPicker()
                case .tagView:      makeTagsView()
                    
                default: EmptyView()
                    
                }
            }
        }
    }
}

