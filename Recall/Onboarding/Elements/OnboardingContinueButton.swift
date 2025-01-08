//
//  OnboardingContinueButton.swift
//  Recall
//
//  Created by Brian Masse on 1/4/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: OnboardingContinueButton
struct OnboardingContinueButton: View {
    
    
//    MARK: Vars
    @ObservedObject var viewModel: OnboardingViewModel = OnboardingViewModel.shared
    
    private let isAsync: Bool
    
    let preTask:            (() -> Void)?
    let asyncPreTask:       (() async -> Void)?
    
    let postTask:           (() -> Void)?
    let asyncPostTask:      (() async -> Void)?
    
    let disableDefaultBehavior: Bool
    
    var greyButton: Bool {
        viewModel.sceneStatus == .incomplete || viewModel.sceneStatus == .async
    }
    
//    MARK: - Non-Async Init
    init(
        disableDefaultBehavior: Bool = false,
        preTask: (() -> Void)? = nil,
        postTask: (() -> Void)? = nil
    ) {
        self.isAsync = false
        self.disableDefaultBehavior = disableDefaultBehavior
        
        self.preTask = preTask
        self.postTask = postTask
        
        self.asyncPreTask = nil
        self.asyncPostTask = nil
    }
    
//    MARK: Async Init
    init(
        disableDefaultBehavior: Bool = false,
        preTask: (() async -> Void)? = nil,
        postTask: (() async -> Void)? = nil
    ) {
        self.isAsync = true
        self.disableDefaultBehavior = disableDefaultBehavior
        
        self.preTask = nil
        self.postTask = nil
        
        self.asyncPreTask = preTask
        self.asyncPostTask = postTask
    }
    
//    MARK: - asyncOnTap
    private func asyncOnTap() async {
        viewModel.setSceneStatus(to: .async)
        if let asyncPreTask { await asyncPreTask() }
        
        if !disableDefaultBehavior {
            viewModel.setSceneStatus(to: .complete)
            viewModel.incrementScene()
        }
        
        if let asyncPostTask { await asyncPostTask() }
    }
    
//    MARK: onTap
    private func onTap() {
        if let preTask { preTask() }
        
        if !disableDefaultBehavior { viewModel.incrementScene() }
        
        if let postTask { postTask() }
    }
    
//    MARK: handleTap
    private func handleTap() {
        if viewModel.sceneStatus != .complete { return }
        
        if isAsync {
            Task { await asyncOnTap() }
        } else {
            onTap()
        }
        
    }
    
//    MARK: - Body
    var body: some View {
        if viewModel.sceneStatus != .hideButton {
            UniversalButton {
                ZStack {
                    HStack {
                        Spacer()
                        
                        RecallIcon("arrow.turn.down.right")
                        
                        UniversalText( "continue", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                        
                        Spacer()
                    }
                    .opacity(greyButton ? 0.25 : 1)
                    .if(viewModel.sceneComplete) { view in view.foregroundStyle(.black) }
                    .rectangularBackground(style: viewModel.sceneComplete ? .accent : .primary)
                    
                    if viewModel.sceneStatus == .async {
                        ProgressView()
                    }
                }
                .padding(7)
                
            } action: { handleTap() }
        }
    }
}
