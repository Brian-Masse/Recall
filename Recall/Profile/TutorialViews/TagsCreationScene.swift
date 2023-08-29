//
//  TagsCreationScene.swift
//  Recall
//
//  Created by Brian Masse on 8/28/23.
//

import Foundation
import SwiftUI
import RealmSwift

extension TutorialViews {

    struct TagsCreationScene: View {
        
//        MARK: Vars
        @ObservedResults(RecallCategory.self) var tags
        
        @State var showingGoalCreationView: Bool = false
        
        @State var name: String = ""
        

        @Binding var scene: TutorialViews.TutorialScene
        @Binding var broadScene: TutorialViews.TutorialScene.BroadScene
        @Binding var nextButtonIsActive: Bool
    
//        MARK: ViewBuilders

        @ViewBuilder
        private func makeSplashScreen() -> some View {
            Group {
                UniversalText("Create your first tag",
                              size: Constants.UITitleTextSize,
                              font: Constants.titleFont)
                .padding(.bottom)
                
                UniversalText( "Tags are a way to organize similar types of events in your life, as well as label how those activites contribute to your goals.",
                               size: Constants.UISubHeaderTextSize,
                               font: Constants.mainFont)
                .padding(.trailing, 20)
            }
            .onAppear { nextButtonIsActive = true }
        }
        
        @ViewBuilder
        private func makeNameView() -> some View {
            TextFieldWithPrompt(title: "Whats the name of this tag?", binding: $name)
                .onChange(of: name) { newValue in
                    if newValue.isEmpty { return }
                    nextButtonIsActive = true
                }
                .slideTransition()
        }
        
        @ViewBuilder
        private func makeColorView() -> some View {
            TextFieldWithPrompt(title: "Whats the name of this tag?", binding: $name)
                .onChange(of: name) { newValue in
                    if newValue.isEmpty { return }
                    nextButtonIsActive = true
                }
                .slideTransition()
        }
        
//        MARK: Body
        
        var body: some View {
            
            VStack(alignment: .leading) {
                
                switch scene {
                case .tagCreation:  makeSplashScreen()
                case .tagName:      makeNameView()
                default: EmptyView()
                    
                }
            }
        }
    }
}

