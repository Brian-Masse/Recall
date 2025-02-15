//
//  OnboardingOnTapAndHoldAnimatino.swift
//  Recall
//
//  Created by Brian Masse on 12/31/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - makeTapAndHoldGestureAnimation
struct TapAndHoldAnimation: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let width: Double = 200
    @State private var height: Double = 30
    
    @State private var showingHand: Bool = true
    @State private var showingCreationView: Bool = false
    
    @Binding var continueButtonIsEnabled: Bool
    
//    MARK: startAnimation
    @MainActor
    private func startAnimation() async{
        withAnimation {
            showingHand = true
            showingCreationView = false
            height = 30
        }
        
        await RecallModel.wait(for: 0.75)
        withAnimation { showingCreationView = true }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            height = 300
        } completion: {
            withAnimation {
                showingHand = false
                showingCreationView = false
                continueButtonIsEnabled = true
                
            } completion: {
                Task {
                    await RecallModel.wait(for: 1.5)
                    await startAnimation()
                }
            }
        }
    }
    
//    MARK: Body
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.clear)
            
            if showingCreationView {
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                        .opacity(0.3)
                    
                    RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                        .stroke(style: .init(lineWidth: 4, lineCap: .round, dash: [5, 10] ))
                    
                }
                .transition(.blurReplace.combined(with: .scale))
                .opacity(0.3)
                
            } else if !showingHand {
                WidgetEventView(event: .init(title: "test",
                                             notes: "notes",
                                             tag: "tag",
                                             startTime: .now,
                                             endTime: .now,
                                             color: Colors.getAccent(from: colorScheme)))
                .redacted(reason: .placeholder)
                .transition(.opacity.combined(with: .scale(0.75)))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showingHand {
                RecallIcon("hand.point.up")
                    .font(.largeTitle)
                    .rotationEffect(.degrees(-30))
                    .padding(.trailing)
                    .offset(y: 25)
                    .transition( .opacity )
            }
        }
        .task { await startAnimation() }
        
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.3), radius: 25, y: 10)
    }
}

#Preview {
    TapAndHoldAnimation(continueButtonIsEnabled: .constant(true))
}
