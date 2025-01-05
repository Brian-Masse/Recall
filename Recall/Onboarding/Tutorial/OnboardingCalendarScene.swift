//
//  OnboardingCalendarScene.swift
//  Recall
//
//  Created by Brian Masse on 12/31/24.
//

import Foundation
import SwiftUI
import UIUniversals
import RealmSwift

//MARK: - OnboardingCalendarAnimationHandler
struct OnboardingCalendarAnimationHandler: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var sceneIndex: Int = 0
    @State private var continueButtonIsEnabled: Bool = false
    
    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
    private let presentedAsSheet: Bool
    
    init(presentedAsSheet: Bool = false) {
        self.presentedAsSheet = presentedAsSheet
    }
    
    private func incrementScene() {
        sceneIndex += 1
        if sceneIndex > 1 {
            if presentedAsSheet {
                dismiss()
            } else {
                viewModel.setSceneStatus(to: .complete)
                viewModel.incrementScene()
            }
        }
    }
    
//    MARK: makeDescriptor
    @ViewBuilder
    private func makeDescriptor(title: String, description: String) -> some View {
        VStack(alignment: .center) {
            UniversalText( title, size: Constants.UISubHeaderTextSize + 3, font: Constants.titleFont )
            
            UniversalText( description, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        }
        .frame(width: 200)
    }
    
//    MARK: ContinueButton
    @ViewBuilder
    private func makeContinueButton() -> some View {
        UniversalButton {
            HStack {
                UniversalText( "Next", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                RecallIcon("arrow.turn.down.right")
            }
            .padding(.horizontal)
            .rectangularBackground(style: continueButtonIsEnabled ? .accent : .secondary)
            .foregroundStyle(.black)
            
        } action: { if continueButtonIsEnabled { incrementScene() }}
    }
    
//    MARK: TapAndHoldAnimation
    @ViewBuilder
    private func makeTapAndHoldAnimationView() -> some View {
        VStack {
            makeDescriptor(title: "Creating Events",
                           description: OnboardingSceneUIText.eventsTapAndHoldGestureInstruction)
            
            TapAndHoldAnimation(continueButtonIsEnabled: $continueButtonIsEnabled)
                .frame(height: 350)
        }
    }
    
//    MARK: ContextMenuAnimation
    @ViewBuilder
    private func makeContextMenuAnimation() -> some View {
        VStack {
            makeDescriptor(title: "Context Menu",
                           description: OnboardingSceneUIText.eventsContextMenuGestureInstruction)
            
            OnboardingContextMenuAnimation(continueButtonIsEnabled: $continueButtonIsEnabled)
                .frame(height: 450)
        }
    }
    
//    MARK: Body
    var body: some View {
        OnboardingSplashScreenView(icon: "calendar.day.timeline.left",
                                   title: "calendar",
                                   message: OnboardingSceneUIText.calendarSceneIntroductionText) {
            VStack {
                switch sceneIndex {
                case 0: makeTapAndHoldAnimationView()
                case 1: makeContextMenuAnimation()
                default: EmptyView()
                }
                
                if sceneIndex <= 1 {
                    makeContinueButton()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                OnboardingContinueButton()
            }
            .onAppear { viewModel.setSceneStatus(to: .hideButton) }
        }
    }
}

//MARK: - OnboardingCalendarScene
struct OnboardingCalendarScene: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedResults( RecallCalendarEvent.self ) var events
    
    @ObservedObject private var viewModel: OnboardingViewModel = OnboardingViewModel.shared
    
    @State private var showingHelpView: Bool = false
    
    private let minimumEvents: Int = 3
    
//    MARK: ViewMethods
    @MainActor
    private func onAppear() async {
//        self.showingCreationView = true
        viewModel.setSceneStatus(to: .hideButton)
        await viewModel.getRecalledEventCount(from: Array(events))
        checkCompletion()
    }
    
    private func checkCompletion() {
        if viewModel.recentRecalledEventCount >= minimumEvents {
//            sceneComplete.wrappedValue = true
        }
    }
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            VStack(alignment: .leading) {
                UniversalText( "Calendar", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                
                UniversalText( OnboardingSceneUIText.calendarSceneInstructionText, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    .opacity(0.75)
            }
        }
    }

//    MARK: makeMinimumEventCounter
    @ViewBuilder
    private func makeMinimumEventCounter() -> some View {
        UniversalText( "\(viewModel.recentRecalledEventCount) / \(minimumEvents)",
                       size: Constants.UIDefaultTextSize,
                       font: Constants.mainFont)
        .rectangularBackground(style: .secondary)
    }
    
//    MARK: makeHelpButton
    @ViewBuilder
    private func makeHelpButton() -> some View {
        UniversalButton {
            UniversalText("?", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
                .rectangularBackground(style: .secondary)
        } action: { showingHelpView = true }

    }
    
//    MARK: makeCalendar
    @ViewBuilder
    private func makeCalendar() -> some View {
        ZStack(alignment: .topTrailing) {
            
            CalendarContainer(events: Array(events), summaries: [])
            
            HStack {
                makeMinimumEventCounter()
                makeHelpButton()
            }
                .padding()
        }
        .overlay {
            if viewModel.sceneComplete {
                LinearGradient(colors: [Colors.getBase(from: colorScheme), .clear],
                               startPoint: .bottom,
                               endPoint: .init(x: 0.5, y: 0.75))
                .contentShape(NullContentShape())
                .ignoresSafeArea()
            }
        }
        .onChange(of: events.count) { Task {
            await viewModel.getRecalledEventCount(from: Array(events))
            checkCompletion()
        } }
    }

    
//    MARK: - Body
    var body: some View {
        
        VStack(alignment: .leading) {
            makeHeader()
                .padding(7)
            
            makeCalendar()
        }
        .overlay(alignment: .bottom) {
            OnboardingContinueButton()
        }
        .task { await onAppear() }
        .sheet(isPresented: $showingHelpView) {
            OnboardingCalendarAnimationHandler(presentedAsSheet: true)
                .background( OnBoardingBackgroundView() )
        }
    }
}

#Preview {
//    OnboardingCalendarAnimationHandler()
    OnboardingCalendarScene()
}
