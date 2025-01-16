//
//  RecallSplashScreenView.swift
//  Recall
//
//  Created by Brian Masse on 1/15/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - RecallSplashScreenView
struct SplashScreen: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
//    MARK: tagLines
    private let tagLines: [String] = [
        "Progress",
        "Details",
        "Excitement",
        "Individuality",
        "Success",
        "Trends",
        "Presence",
        "Mastery"
    ]
    
    
//    MARK: Vars
    @State private var progress: Double = 0
    @State private var showingLogo: Bool = false
    @State private var screenComplete: Bool = false
    @State private var showingButtons: Bool = false
    
    @State private var currentTagLine: Int = 0
        
    private let logoAnimationDuration: Double = 1.5
    
    private let tagLineFontSize: Double = (Constants.UISubHeaderTextSize + 5)
    private let tagLineInterval: Double = 2
    
//    MARK: makeBackground
    @ViewBuilder
    private func makeBackground() -> some View {
        ZStack {
            OnBoardingBackgroundView(boostColor: true)
                .zIndex(1)
            
            OnBoardingBackgroundView(boostColor: true)
                .rotationEffect(.degrees(180))
                .zIndex(1)
            
            if !screenComplete {
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                    .foregroundStyle(.background)
                    .blur(radius: 20)
                    .transition(.scale(0.75).combined(with: .opacity) )
                    .zIndex(2)
            }
        }
        .ignoresSafeArea()
    }
    
//    MARK: - incrementTagLine
    private func incrementTagLine() async {
        await RecallModel.wait(for: tagLineInterval)
        
        withAnimation(.spring) {
            currentTagLine = (currentTagLine + 1) % tagLines.count
        } completion: {
            Task { await incrementTagLine() }
        }
    }
    
//    MARK: makeIndividualTagLine
    @ViewBuilder
    private func makeIndividualTagLine() -> some View {
        UniversalText( tagLines[currentTagLine], size: tagLineFontSize, font: Constants.titleFont )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 3)
            }
            .transition( .asymmetric(insertion: .offset(y: 40).combined(with: .scale(scale: 0.75).combined(with: .opacity)),
                                     removal: .offset(y: -40).combined(with: .opacity).combined(with: .scale(scale: 0.75)) )  )
    }
    
//    MARK: makeTagLIne
    @ViewBuilder
    private func makeTagLine() -> some View {
        VStack {
            HStack {
                Spacer()
                UniversalText( "Find the", size: tagLineFontSize, font: Constants.mainFont )
                    .opacity(0.65)
                
                if currentTagLine & 1 == 0 {
                    makeIndividualTagLine()
                } else {
                    makeIndividualTagLine()
                }
                Spacer()
            }
        
            UniversalText( "in your life.", size: tagLineFontSize, font: Constants.mainFont )
                .opacity(0.65)
        }
        .task { await incrementTagLine() }
    }
    
//    MARK: - makeContent
    @ViewBuilder
    private func makeContent() -> some View {
        
        VStack {
            GradientText("Recall")
                .scaleEffect(2)
                .padding(.bottom, 7)
            
            makeTagLine()
        }
    }
    
//    MARK: makeButtons
    @ViewBuilder
    private func makeButtons() -> some View {
        UniversalButton {
            HStack {
                Spacer()
                UniversalText( "I am new to Recall", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                
                RecallIcon("fireworks")
                Spacer()
            }.rectangularBackground(10, style: .primary)
            
        } action: { RecallModel.realmManager.setState(.onboarding) }
            .padding(.bottom, 7)
        
        UniversalButton {
            HStack {
                UniversalText( "I already have a Recall account", size: Constants.UISmallTextSize, font: Constants.mainFont )
            }.opacity(0.75)
        } action: { RecallModel.realmManager.setState(.authenticating) }
    }
    
//    MARK: - Body
    var body: some View {
        
        ZStack {
            FullScreenProgressBar(progress: progress)
                .universalStyledBackgrond(.accent, onForeground: true)
            
            VStack {
                Spacer()
                
                if showingLogo && !screenComplete {
                    LogoAnimation(duration: logoAnimationDuration)
                        .transition(.scale(1.5).combined(with: .opacity) )
                } else if screenComplete {
                    makeContent()
                        .transition(.blurReplace)
                }
                
                Spacer()
                
                if showingButtons {
                    makeButtons()
                        .padding(.horizontal, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { makeBackground() }
        .task {
            await RecallModel.wait(for: 0.5)
            showingLogo = true
            
            withAnimation(.spring(duration: logoAnimationDuration)) {
                progress = 1
            } completion: {
                withAnimation { screenComplete = true }
                
                Task {
                    await RecallModel.wait(for: tagLineInterval)
                    withAnimation { showingButtons = true }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
}
