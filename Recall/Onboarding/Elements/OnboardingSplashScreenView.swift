//
//  OnboardingSplashScreenView.swift
//  Recall
//
//  Created by Brian Masse on 12/28/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: OnboardingSplashScreenView
struct OnboardingSplashScreenView<C: View>: View {
    
    @ViewBuilder private var contentBuilder: () -> C
    
    private let icon: String
    private let title: String
    private let message: String
    
    @Namespace private var namespace
    
    private let startDate = Date.now
    private let interval: Double = 0.75
    
    @State private var showingSplash: Bool = false
    @State private var showingMessage: Bool = false
    @State private var showingContent: Bool = false
    
    init(
        icon: String,
        title: String,
        message: String,
        
        @ViewBuilder contentBuilder: @escaping () -> C
    ) {
        self.contentBuilder = contentBuilder
        self.icon = icon
        self.title = title
        self.message = message
    }
    
    private func handleTimeline(_ context: TimelineViewDefaultContext) {
        if context.date >= startDate + interval { showingMessage = true }
        if context.date >= startDate + interval * 4 { showingContent = true }
    }
    
    var body: some View {
        
        ZStack {
            if !showingContent {
                TimelineView(.periodic(from: startDate, by: interval)) { context in
                    VStack {
                        if showingSplash {
                            VStack {
                                RecallIcon(icon)
                                    .font(.largeTitle)
                                
                                UniversalText(title, size: Constants.UIHeaderTextSize, font: Constants.titleFont)
                                    .padding(.bottom)
                                
                                if showingMessage {
                                    UniversalText( message,
                                                   size: Constants.UIDefaultTextSize,
                                                   font: Constants.mainFont,
                                                   textAlignment: .center)
                                    .opacity(0.75)
                                }
                            }
                            .frame(width: 200)
                            .transition(.blurReplace
                                .combined(with: .scale)
                                .combined(with: .offset(.init(width: 0, height: 100))))
                        }
                    }
                    .onChange(of: context.date ) { withAnimation { handleTimeline(context) }}
                    .onAppear { withAnimation { showingSplash = true } }
                }
                .transition(.asymmetric(insertion: .identity,
                                        removal: .offset(x: 0, y: -100).combined(with: .opacity)))
            } else {
                contentBuilder()
                    .transition(.blurReplace)
            }
        }
    }
}
