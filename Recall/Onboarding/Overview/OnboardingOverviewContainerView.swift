//
//  OnboardingOverviewContainerView.swift
//  Recall
//
//  Created by Brian Masse on 1/12/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - OnboardingOverviewContainerView
struct OnboardingOverviewContainerView: View {
    
//    MARK: OverviewScene
    struct OnboardingOverviewScene {
        let icon: String
        let description: String
    }
    
    @Binding private var currentSceneIndex: Int
    
    private let scenes: [OnboardingOverviewScene]
    private let splashIcon: String
    private let splashText: String
    private let textBackground: Bool
    
    private func incrementScene() {
        withAnimation(.spring) {
            self.currentSceneIndex = min( currentSceneIndex + 1, scenes.count - 1 )
        }
    }
    
    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
    private var onFinalScene: Bool {
        currentSceneIndex >= scenes.count - 1
    }
    
    
//    MARK: Init
    init(
        _ scenes: [OnboardingOverviewScene],
        currentSceneIndex: Binding<Int>,
        textBackground: Bool = false,
        splashScreen: OnboardingOverviewScene
    ) {
        self.scenes = scenes
        self.splashIcon = splashScreen.icon
        self.splashText = splashScreen.description
        self.textBackground = textBackground
        self._currentSceneIndex = currentSceneIndex
    }
    
//    MARK: - makeDescription
    @ViewBuilder
    private func makeDescription(index: Int) -> some View {
        
        let scene = scenes[index]
        
        let opacity = 1 / max(Double( currentSceneIndex + 1 - index ), 1)
        
        VStack {
            RecallIcon( scene.icon )
                .font(.largeTitle)
                .padding(.bottom)
            
            UniversalText(scene.description, size: Constants.UISubHeaderTextSize, font: Constants.mainFont, textAlignment: .center)
                .opacity(0.75)
        }
        .opacity(opacity)
        .transition(.offset(y: -50).combined(with: .scale(0.75).combined(with: .opacity) ))
    }
    
//    MARK: - makeContinueButton
    @ViewBuilder
    private func makeContinueButton() -> some View {
        UniversalButton {
            HStack {
                UniversalText( "Next", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                RecallIcon("arrow.turn.up.right")
            }
            .highlightedBackground(true)
            
        } action: { incrementScene() }
    }
    
//    MARK: - Body
    var body: some View {
         
        
        
        OnboardingSplashScreenView(icon: splashIcon,
                                   title: splashText,
                                   message: "",
                                   duration: 2.5) {
            VStack {
                VStack {
                    
                    Spacer()
                    
                    VStack {
                        if !onFinalScene {
                            ForEach( 0..<scenes.count, id: \.self ) { i in
                                let index = scenes.count - 1 - i
                                
                                if index <= currentSceneIndex {
                                    makeDescription(index: index)
                                        .padding(.vertical, 7)
                                }
                            }
                            
                        } else  { makeDescription(index: scenes.count - 1) }
                    }
                    .frame(width: 250)
                    .padding(20)
                    .background {
                        if !onFinalScene && currentSceneIndex > 0 && textBackground {
                            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                                .foregroundStyle(.ultraThinMaterial)
                        }
                    }
                    
                    Spacer()
                    
                    if currentSceneIndex < scenes.count - 1 {
                        makeContinueButton()
                    }
                }
            }
            .onAppear { viewModel.setSceneStatus(to: .hideButton) }
            .onChange(of: currentSceneIndex) {
                viewModel.setSceneStatus(to: !onFinalScene ? .hideButton : .complete  )
            }
            
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                OnboardingContinueButton()
            }
        }
    }
}
