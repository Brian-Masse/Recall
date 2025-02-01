//
//  OnboardingCompleteView.swift
//  Recall
//
//  Created by Brian Masse on 1/26/25.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - SpinningText
struct SpinningText: View {
    
    let text: String
    let radius: Double
    
    var body: some View {
        
        ZStack {
        
            let increment : Double = 2 * Double.pi / Double(text.count)
            
            ForEach( 0..<text.count, id: \.self ) { i in
                    
                let angle = Double(i) * increment
                
                
                UniversalText( String( text[ text.index(text.startIndex, offsetBy: i) ] ),
                               size: Constants.UISubHeaderTextSize + 4,
                               font: Constants.titleFont )
                .rotationEffect(.radians(angle + Double.pi / 2))
                .offset(x: radius * cos(angle), y: radius * sin(angle))
            }
        }
    }
}

//MARK: - OnboardingCompleteView
struct OnboardingCompleteView: View {

    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
//    MARK: Body
    var body: some View {
        
        VStack {
            LogoAnimation(autoReverse: false)
            
            UniversalText( "You're all set!",
                           size: Constants.UIHeaderTextSize,
                           font: Constants.titleFont,
                           textAlignment: .center)
            .padding(.bottom, 7)
            
            UniversalText( "Jump into Recall to start finding presence in your life",
                           size: Constants.UISubHeaderTextSize,
                           font: Constants.mainFont,
                           textAlignment: .center)
            .opacity(0.75)
        }
        .frame(width: 220)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { viewModel.setSceneStatus(to: .complete) }
        .overlay(alignment: .bottom) {
            OnboardingContinueButton()
        }
    }
}

#Preview {
    
    OnboardingCompleteView()
    
}
