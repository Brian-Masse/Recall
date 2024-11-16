//
//  EventsCreationScene.swift
//  Recall
//
//  Created by Brian Masse on 8/29/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

extension TutorialViews {

    struct EventsCreationScene: View {
        
//        MARK: Vars
        @ObservedResults(RecallGoal.self,
                         where: { goal in goal.ownerID == RecallModel.ownerID }) var goals
        @ObservedResults(RecallCategory.self,
                         where: { tag in tag.ownerID == RecallModel.ownerID }) var tags
        @ObservedResults(RecallCalendarEvent.self,
                         where: { event in event.ownerID == RecallModel.ownerID}) var events
        
        @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
        
        @State var showingAllGoals: Bool = false
        @State var sentFirstEvent: Bool = false
        
        @State var name: String = ""
        @State var notes: String = ""
        @State var startTime: Date = .now
        @State var endTime: Date = .now + Constants.HourTime
        @State var tag: RecallCategory = RecallCategory()
        @State var goalRatings: Dictionary<String, String> = Dictionary()

        @Binding var scene: TutorialViews.TutorialScene
        @Binding var broadScene: TutorialViews.TutorialScene.BroadScene
        @Binding var nextButtonIsActive: Bool

        
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
        
//        MARK: Basic Info
        @ViewBuilder
        private func makeNameView() -> some View {
            StyledTextField(title: "What was the first thing you did today?", binding: $name)
                .onChange(of: name) {
                    if name.isEmpty { return }
                    nextButtonIsActive = true
                }
                .slideTransition()
        }
        
        @ViewBuilder
        private func makeNotesView() -> some View {
            StyledTextField(title: "Add additional notes about this event", binding: $notes)
                .onChange(of: notes) {
                    if notes.isEmpty { return }
                    nextButtonIsActive = true
                }
                .slideTransition()
        }
        
        @ViewBuilder
        private func makeTimesView() -> some View {
            VStack(alignment: .leading) {
                
                UniversalText( "When did this event happen?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                    .padding(.bottom, 5)
                UniversalText( "In your recall calendar view, you can tap and hold on events to more precisley move and resize them.",
                               size: Constants.UIDefaultTextSize,
                               font: Constants.mainFont)
                .padding([.bottom, .trailing ])
                
                TimeSelector(label: "When did this event start?", time: $startTime)
                    .padding(.bottom)
                
                TimeSelector(label: "When did this event end?", time: $endTime)
            }
            .padding(.horizontal, 5)
            .slideTransition()
            .onAppear { nextButtonIsActive = true }
        }
        
//        MARK: Tag and Goal Selector
        @ViewBuilder
        private func makeTagSelector(tag: RecallCategory) -> some View {
            HStack {
                RecallIcon("tag")
                UniversalText(tag.label, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            }
            .onTapGesture { self.tag = tag }
            .if(self.tag.label == tag.label) { view in view.rectangularBackground(style: .accent, foregroundColor: .black)  }
            .if(self.tag.label != tag.label) { view in view.rectangularBackground(style: .secondary) }
        }
        
        @ViewBuilder
        private func makeTagSelector() -> some View {
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    UniversalText("What tag best categorizes this event?", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                        .padding(.bottom, 7)
                    
                    WrappedHStack(collection: Array(tags)) { tag in
                        makeTagSelector(tag: tag)
                    }
                    .padding(.bottom, 7)
                    
                    LargeRoundedButton("create another tag", icon: "arrow.up", wide: true) { coordinator.presentSheet(.tagCreationView(editting: false))  }
                }
            }
            .slideTransition()
            .onChange(of: tag) {
                if tag.label != "" && !tag.label.isEmpty {
                    nextButtonIsActive = true
                } else {
                    nextButtonIsActive = false
                }
            }
        }
        
        @ViewBuilder
        private func makeGoalModifier() -> some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    UniversalText("Change goal multipliers for this event", size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                        .padding(.bottom, 5)
                    UniversalText( "just as tags have unique multipliers for goals, individual events can also change how much they do or do not contribute to a goal, beyond their tag.",
                                   size: Constants.UIDefaultTextSize,
                                   font: Constants.mainFont)
                        .padding(.bottom)
                    
                    if tag.goalRatings.count > 0 {
                        UniversalText("Goals specified by tag", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                        ForEach( Array(goals), id: \.key ) { goal in
                            if tag.goalRatings.contains(where: { node in node.key == goal.key }) {
                                GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: true)
                            }
                        }
                    }
                    
                    HStack {
                        UniversalText("All Goals", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                        Spacer()
                        LargeRoundedButton("", icon: showingAllGoals ? "arrow.up" : "arrow.down") { showingAllGoals.toggle() }
                    }.padding(.top)
                    
                    VStack {
                        if showingAllGoals {
                            ForEach( Array(goals), id: \.key ) { goal in
                                GoalMultiplierSelector(goal: goal, goalRatings: $goalRatings, showToggle: true)
                            }
                        }
                    }
                }
            }
            .slideTransition()
            .onAppear() {
                nextButtonIsActive = true
                goalRatings = RecallCalendarEvent.translateGoalRatingList( tag.goalRatings )
            }
        }
        
//        MARK: CalendarView
        @ViewBuilder
        private func makeCalendarView() -> some View {
            VStack {
                GeometryReader { geo in
                    StyledCalendarContainerView(at: .now,
                                                with: Array(events),
                                                from: 0, to: 24,
                                                geo: geo,
                                                scale: 2)
                }
                LargeRoundedButton("Recall", icon: "arrow.up", wide: true) { coordinator.presentSheet(.eventCreationView()) }
            }
            .slideTransition()
            .onAppear() {
                nextButtonIsActive = true
                
                if sentFirstEvent { return }
                let event = RecallCalendarEvent(ownerID: RecallModel.ownerID,
                                                title: name,
                                                notes: notes,
                                                urlString: "",
                                                startTime: startTime,
                                                endTime: endTime,
                                                categoryID: tag._id,
                                                goalRatings: goalRatings)
                
                RealmManager.addObject( event )
                sentFirstEvent = true
                
            }
        }
        

//        MARK: Body        
        var body: some View {
            
            VStack(alignment: .leading) {
                
                switch scene {
                case .eventCreation:    makeSplashScreen()
                case .eventName:        makeNameView()
                case .eventNotes:       makeNotesView()
                case .eventTime:        makeTimesView()
                case .eventTag:         makeTagSelector()
                case .eventGoals:       makeGoalModifier()
                case .eventView:        makeCalendarView()
                    
                default: EmptyView()
                    
                }
            }
        }
    }
}


