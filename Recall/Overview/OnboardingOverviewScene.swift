//
//  OnboardingOverviewScene.swift
//  Recall
//
//  Created by Brian Masse on 1/9/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - OnboardingOverviewScene
struct OnboardingOverviewScene: View {
    
    
//    MARK: OverviewScene
    private enum OverviewScene: Int {
        case whatIsRecall
        case calendar
        case reverse
        case description
        
        var title: String {
            switch self {
            case .whatIsRecall:     return "What is Recall?"
            default:                return ""
            }
        }
        
        var description: String {
            switch self {
            case .calendar:          return "Recall is a calendar app"
            case .reverse:           return "In reverse"
            case .description:       return "Recall records what you actually do every day, allowing you to better track progress towards your goals, observe trends, and become more present in your life"
            default:                 return ""
            }
        }
        
        func incrementScene() -> OverviewScene {
            .init(rawValue: rawValue + 1) ?? self
        }
    }
    
//    MARK: Vars
    @State private var scene: OverviewScene = .whatIsRecall
    
        
//    MARK: - titleText
    @State private var t: Double = 0
    @State private var timer: Timer?
    
    private func getTitleGradientOffset(in width: Double) -> Double {
        t.truncatingRemainder(dividingBy: width)
    }
    
    @ViewBuilder
    private func makeTitleText(_ text: String) -> some View {
        UniversalText( text, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
    }
    
    @ViewBuilder
    private func makeGradient() -> some View {
        LinearGradient(colors: [.red, .blue, .red], startPoint: .leading, endPoint: .trailing)
    }
    
//    MARK: makeTitle
    @ViewBuilder
    private func makeTitle(_ title: String) -> some View {
        
        makeTitleText(title)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        makeGradient()
                        makeGradient()
                    }
                        .frame(width: 2 * geo.size.width)
                        .offset(x: getTitleGradientOffset(in: geo.size.width))
                    
                        .onAppear {
                            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in t -= 1 }
                        }
                }
                .mask { makeTitleText(title) }
            }
    }
    
    
//    MARK: - makeDescription
    @ViewBuilder
    private func makeDescription(_ description: String) -> some View {
        UniversalText(description, size: Constants.UISubHeaderTextSize, font: Constants.mainFont)
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
            
        } action: { self.scene = scene.incrementScene() }
    }
    
//    MARK: - Body
    var body: some View {
         
        VStack {
            
            Spacer()
            
            makeTitle(scene.title)
            makeDescription(scene.description)
                .transition(.scale)
            
            Spacer()
            
            makeContinueButton()
            
            Spacer()
            
        }
        .frame(width: 250)
    }
    
}

#Preview {
    OnboardingOverviewScene()
}
