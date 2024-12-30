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
    
    private let width: Double = 200
    @State private var height: Double = 30
    
    @State private var showingHand: Bool = true
    @State private var showingCreationView: Bool = false
    
    @Binding var continueButtonIsEnabled: Bool
    
//    MARK: startAnimation
    @MainActor
    private func startAnimation() async{
        await RecallModel.wait(for: 2)
        
        withAnimation { showingCreationView = true }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            height = 300
        } completion: {
            withAnimation {
                showingHand = false
                showingCreationView = false
                continueButtonIsEnabled = true
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
                        .foregroundStyle(.gray)
                    
                    RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                        .stroke(style: .init(lineWidth: 4, lineCap: .round, dash: [5, 10] ))
                    
                }
                .transition(.blurReplace.combined(with: .scale))
                .opacity(0.4)
                
            } else if !showingHand {
                WidgetEventView(event: .init(title: "test",
                                             notes: "notes",
                                             tag: "tag",
                                             startTime: .now,
                                             endTime: .now,
                                             color: .red))
                .redacted(reason: .placeholder)
                .transition(.blurReplace)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showingHand {
                RecallIcon("hand.point.up")
                    .font(.largeTitle)
                    .rotationEffect(.degrees(-30))
                    .padding(.trailing)
                    .offset(y: 25)
                    .transition(.blurReplace)
            }
        }
        .task { await startAnimation() }
        
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.3), radius: 25, y: 10)
    }
}
