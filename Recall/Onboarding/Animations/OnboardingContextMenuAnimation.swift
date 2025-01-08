//
//  OnboardingContextMenuAnimation.swift
//  Recall
//
//  Created by Brian Masse on 12/31/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: OnboardingContextMenuAnimation
struct OnboardingContextMenuAnimation: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let contextMenuItemsCount: Int = 5
    
    private let size: CGSize = .init(width: 200, height: 250)
    
    @State private var showingContextMenu: Bool = false
    
    @Binding var continueButtonIsEnabled: Bool
    
//    MARK: startAnimation
    private func startAnimation() async {
        await RecallModel.wait(for: 2)
        
        withAnimation {
            showingContextMenu = true
        } completion: {
            Task {
                await RecallModel.wait(for: 1.5)
                
                withAnimation {
                    showingContextMenu = false
                    continueButtonIsEnabled = true
                } completion: {
                    Task { await startAnimation() }
                }
            }
        }
    }
    
//    MARK: makeContextMenu
    @ViewBuilder
    private func makeContextMenu() -> some View {
        
        VStack(spacing: 15) {
            ForEach( 0..<contextMenuItemsCount, id: \.self ) { _ in
                HStack {
                    RecallIcon( "hand.point.up")
                    Text("hi there Length!")
                }
            }
        }
        .zIndex(1)
        .rectangularBackground(style: .transparent)
        .transition(.blurReplace.combined(with: .scale(0.2, anchor: .top) ))
        .shadow(color: .black.opacity(0.2), radius: 15, y: 15)
    }
    
//    MARK: makeEvent
    @ViewBuilder
    private func makeEvent() -> some View {
        WidgetEventView(event: .init(
            title: "test event",
            notes: "notes",
            tag: "tag",
            startTime: .now,
            endTime: .now,
            color: Colors.getAccent(from: colorScheme)
        ))
        .zIndex(0)
        .frame(width: size.width, height: size.height)
        .blur(radius: showingContextMenu ? 3 : 0)
    }
    
//    MARK: Body
    var body: some View {
        
        VStack {
            makeEvent()
            
            
            if showingContextMenu {
                makeContextMenu()
                    .offset(y: -50)
            }
        }
        .redacted(reason: .placeholder)
        .overlay(alignment: .topTrailing) { if !showingContextMenu {
            RecallIcon("hand.point.up")
                .rotationEffect(.degrees(-30))
                .font(.largeTitle)
                .padding()
                .transition(.blurReplace)
        } }
        
        .task { await startAnimation() }
    }
}
