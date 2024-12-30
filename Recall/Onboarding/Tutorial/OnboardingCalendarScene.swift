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

//MARK: OnboardingCalendarScene
struct OnboardingCalendarScene: View, OnboardingSceneView {
    
    var sceneComplete: Binding<Bool>
    
    @ObservedResults( RecallCalendarEvent.self ) var events
    
    @ObservedObject private var viewModel: OnboardingViewModel = OnboardingViewModel.shared
    
    @State private var showingCreationView: Bool = false
    
    private let minimumEvents: Int = 3
    
//    MARK: ViewMethods
    @MainActor
    private func onAppear() async {
        self.showingCreationView = true
        await viewModel.getRecalledEventCount(from: Array(events))
        checkCompletion()
    }
    
    private func checkCompletion() {
        if viewModel.recentRecalledEventCount >= minimumEvents {
            sceneComplete.wrappedValue = true
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
    

    
//    MARK: - Body
    var body: some View {
        
        TapAndHoldAnimation()
        
//        ZStack(alignment: .topTrailing) {
//            
//            CalendarContainer(events: Array(events), summaries: [])
//            
//            makeMinimumEventCounter()
//                .padding()
//        }
//        .background()
//        .overlay {
//            LinearGradient(colors: [.black, .clear],
//                           startPoint: .bottom,
//                           endPoint: .init(x: 0.5, y: 0.75))
//            .contentShape(NullContentShape())
//            .ignoresSafeArea()
//        }
//        .task { await onAppear() }
//        .onChange(of: events.count) { Task {
//            await viewModel.getRecalledEventCount(from: Array(events))
//            checkCompletion()
//        } }
//        .sheet(isPresented: $showingCreationView) {
//            CalendarEventCreationView.makeEventCreationView(
//                editing: false,
//                formTitle: "What was your first event today?"
//            )
//        }
    }
}

#Preview { OnboardingCalendarScene(sceneComplete: .constant(true)) }
