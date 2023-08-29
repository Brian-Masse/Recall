//
//  GoalsCreationScene.swift
//  Recall
//
//  Created by Brian Masse on 8/28/23.
//

import Foundation
import SwiftUI
import RealmSwift

extension TutorialViews {

    struct GoalCreationScene: View {
        
//        MARK: Vars
        @ObservedResults(RecallGoal.self) var goals
        
        @State var showingGoalCreationView: Bool = false
        
        @State var name: String = ""
        @State var description: String = ""
        @State var frequence: RecallGoal.GoalFrequence = .weekly
        @State var targetHours: Float = 0

        @Binding var scene: TutorialViews.TutorialScene
        @Binding var broadScene: TutorialViews.TutorialScene.BroadScene
        @Binding var nextButtonIsActive: Bool
        
        private var hoursBinding: Binding<String> {
            Binding { "\(Int( targetHours ))"
            } set: { newValue, _ in
                targetHours = Float( newValue ) ?? 0
            }

        }
    
//        MARK: ViewBuilders
        struct EnumOption: View {
            
            let option: RecallGoal.GoalFrequence
            let label: String
            
            @Binding var selected: RecallGoal.GoalFrequence
        
            var body: some View {
                
                HStack {
                    
                    Spacer()
                    UniversalText( label, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                    Spacer()
                    
                }
                .if( selected == option ) { view in view.tintRectangularBackground() }
                .if( selected != option ) { view in view.secondaryOpaqueRectangularBackground() }
                .onTapGesture { selected = option }
            }
        }
        
//        MARK: SplashScreen
        @ViewBuilder
        private func makeSplashScreen() -> some View {
            Group {
                UniversalText("Create your first goal",
                              size: Constants.UITitleTextSize,
                              font: Constants.titleFont)
                .padding(.bottom)
                
                //            They can be as narrow as eating 3 meals a day or as open as staying productive.
                UniversalText( "Goals allow you to automatically count certain activities towards the personal goals in your life." ,
                               size: Constants.UISubHeaderTextSize,
                               font: Constants.mainFont)
                .padding(.trailing, 20)

            }
            .onAppear { nextButtonIsActive = true }
            .slideTransition()
                           
        }
        
//        MARK: Basic Info
        @ViewBuilder
        private func makeNameView() -> some View {
            TextFieldWithPrompt(title: "What is the name of your goal?", binding: $name)
                .onChange(of: name) { newValue in
                    if newValue.isEmpty { return }
                    nextButtonIsActive = true
                }
                .slideTransition()
        }
        
        @ViewBuilder
        private func makeDescriptionView() -> some View {
            TextFieldWithPrompt(title: "What is the purpose of this goal?", binding: $description)
                .onChange(of: description) { newValue in
                    if newValue.isEmpty { return }
                    nextButtonIsActive = true
                }
                .slideTransition()
        }
        
        @ViewBuilder
        private func makeTimingSelectorView() -> some View {
            
            Group {
                UniversalText( "How frequently would you like to meet this goal?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                HStack {
                    EnumOption(option: .daily, label: "daily", selected: $frequence)
                    EnumOption(option: .weekly, label: "weekly", selected: $frequence)
                }
                .padding(.bottom)
                
                SliderWithPrompt(label: "And how many hours do you want to spend on this goal?",
                                 minValue: 0,
                                 maxValue: (frequence == .daily ? 12 : 50 ),
                                 binding: $targetHours,
                                 strBinding: hoursBinding,
                                 textFieldWidth: Constants.UIFormSliderTextFieldWidth)
            }
            .slideTransition()
            .onAppear() { nextButtonIsActive = true }
        }
        
//        MARK: GoalsOverview
        @ViewBuilder
        private func makeMetaDataLabel(title: String, description: String) -> some View {
            
            HStack {
                Spacer()
                VStack {
                    UniversalText( title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                    UniversalText( description, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                }
                Spacer()
            }
            .secondaryOpaqueRectangularBackground()
            
        }
        
        @ViewBuilder
        private func makeGoalOverview(_ goal: RecallGoal) -> some View {
            
            VStack(alignment: .leading) {
                UniversalText( goal.label, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                    .padding(.bottom, 5)
                UniversalText( goal.goalDescription, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                
                HStack {
                    makeMetaDataLabel(title: RecallGoal.GoalFrequence.getRawType(from: goal.frequency).rawValue, description: "frequency")
                    makeMetaDataLabel(title: "\(goal.targetHours)", description: "hours")
                }
            }
            .opaqueRectangularBackground(7, stroke: true)
        }
        
        @ViewBuilder
        private func makeGoalsOverview() -> some View {
            
            VStack(alignment: .leading) {
                
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        ForEach( goals, id: \.label ) { goal in
                            makeGoalOverview(goal)
                        }
                    }
                }
                
                LargeRoundedButton("add anohter goal", icon: "arrow.up", wide: true) { showingGoalCreationView = true }
            }
            .slideTransition()
            .sheet(isPresented: $showingGoalCreationView) {
                GoalCreationView.makeGoalCreationView(editing: false)
            }
            .onAppear {
                nextButtonIsActive = true
                
                if goals.first(where: { goal in goal.label == name }) != nil { return }
                
                let goal = RecallGoal(ownerID: RecallModel.ownerID,
                                      label: name,
                                      description: description,
                                      frequency: frequence.numericValue,
                                      targetHours: Int(targetHours),
                                      priority: .medium,
                                      type: .hourly,
                                      targetTag: nil)
                
                RealmManager.addObject(goal)
            }
            .onDisappear { broadScene = .tag }
        }
        
        
        var body: some View {
            
            VStack(alignment: .leading) {
                
                switch scene {
                case .goalCreation:     makeSplashScreen()
                case .goalName:         makeNameView()
                case .goalPurpose:      makeDescriptionView()
                case .goalTiming:       makeTimingSelectorView()
                case .goalView:         makeGoalsOverview()
                default: EmptyView()
                    
                }
            }
        }
    }
}
