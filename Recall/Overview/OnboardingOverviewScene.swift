//
//  OnboardingOverviewScene.swift
//  Recall
//
//  Created by Brian Masse on 1/9/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - GradientText
private struct GradientText: View {
    
    @State private var t: Double = 0
    @State private var timer: Timer?
    
    private let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    private func getTitleGradientOffset(in width: Double) -> Double {
        t.truncatingRemainder(dividingBy: width)
    }
    
    @ViewBuilder
    private func makeTitleText(_ text: String) -> some View {
        UniversalText( text, size: Constants.UIHeaderTextSize + 5, font: Constants.titleFont )
    }
    
    @ViewBuilder
    private func makeGradient() -> some View {
        LinearGradient(colors: [.red, .blue, .red], startPoint: .leading, endPoint: .trailing)
    }

    
    var body: some View {
        makeTitleText(text)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        makeGradient()
                        makeGradient()
                    }
                        .frame(width: 2 * geo.size.width)
                        .offset(x: getTitleGradientOffset(in: geo.size.width))
                    
                        .onAppear {
                            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in t -= 0.5 }
                        }
                }
                .mask { makeTitleText(text) }
            }
    }
}



//MARK: - OnboardingOverviewScene
struct OnboardingOverviewScene: View {
    
    
//    MARK: OverviewScene
    private struct OnboardingOverviewScene {
        let icon: String
        let description: String
    }
    
    private let scenes: [OnboardingOverviewScene] = [
        
        .init(icon: "calendar",
              description: "Recall is a calendar app designed for remembering, recording, and saving all the events that go into your life"),
        
            .init(icon: "memories",
                  description: "You can browse the events you log to look back on meaningful memories, remember important days, and celebrate progress"),
        
        .init(icon: "flag.pattern.checkered.2.crossed",
              description: "Recall also intelligently uses the events you record to accurately track your progress towards the goals you have set for yourself "),
        
        .init(icon: "checkmark.circle",
              description: "Recall keeps you present in the details of your life, while enabling you to look ahead to its future")
        
    ]
    
    
    
//    MARK: Vars
    @Namespace private var namespace
    
    @State private var currentSceneIndex: Int = 0
    
    private func incrementScene() {
        withAnimation(.bouncy) {
            self.currentSceneIndex = min( currentSceneIndex + 1, scenes.count - 1 )
        }
    }
        
//    MARK: - titleText
    
    
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
         
        
        
//        OnboardingSplashScreenView(icon: "calendar",
//                                   title: "What is Recall?",
//                                   message: "",
//                                   duration: 4) {
//        
            VStack {
                
                Spacer()
                
                if currentSceneIndex < scenes.count - 1 {
                    ForEach( 0..<scenes.count, id: \.self ) { i in
                        let index = scenes.count - 1 - i
                        
                        if index <= currentSceneIndex {
                            makeDescription(index: index)
                                .padding(.vertical, 7)
                        }
                    }
                    
                } else {
                    makeDescription(index: scenes.count - 1)
                }
                
                Spacer()
                
                makeContinueButton()
            }
            .frame(width: 250)
            
//        }
    }
}

#Preview {
    OnboardingOverviewScene()
}
