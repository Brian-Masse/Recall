//
//  AboutEventView.swift
//  Recall
//
//  Created by Brian Masse on 12/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

struct AboutScreenEventModel {
    let event: RecallWidgetCalendarEvent
    let indexOfText: Int
    let relativeDelay: Double
    let position: CGPoint
    let size: CGSize
}

//MARK: AboutScreenEventView
struct AboutScreenEventView: View {

    
//    MARK: makeEventView
    @ViewBuilder
    private func makeEventLabel(_ icon: String, title: String) -> some View {
        HStack {
            RecallIcon(icon)
                .font(.caption)
            
            UniversalText( title, size: Constants.UISmallTextSize, font: Constants.mainFont )
        }.opacity(0.75)
    }
    
    @ViewBuilder
    private func makeEventContent() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            
            makeEventLabel("clock", title: "\(event.timeString)")
            
            makeEventLabel("tag", title: "\(event.tag)")
            
            if !event.notes.isEmpty {
                makeEventLabel("text.alignleft", title: "\(event.notes)")
            }
        }
    }
    
    @ViewBuilder
    private func makeEventView() -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                .frame(width: 5)
                .foregroundStyle(event.color)
                
            VStack(alignment: .leading, spacing: 10) {
                UniversalText( event.title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                
                if size.height >= contentHeightThreshold {
                    makeEventContent()
                    
                    Spacer()
                }
            }
            .foregroundStyle(event.color.safeMix(with: .black, by: 0.5))
            
            Spacer()
        }
        
        .frame(width: size.width, height: size.height)
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                .foregroundStyle(event.color)
                .opacity(0.4)
        }
    }
    
//    MARK: AboutScreenEventViewInit
    init(
        event: RecallWidgetCalendarEvent,
        size: CGSize = .init(width: 150, height: 175),
        position: CGPoint = .zero,
        relatvieDelay: Double,
        dissapearDelay: Double
    ) {
        self.event = event
        self.size = size
        self.position = position
        self.relativeDelay = relatvieDelay
        self.dissapearDelay = dissapearDelay
    }
    
    let event: RecallWidgetCalendarEvent

    private let contentHeightThreshold: Double = 115
    
    private let size: CGSize
    private let position: CGPoint
    private let relativeDelay: Double
    private let dissapearDelay: Double
    
    @State private var isShowing: Bool = false
    
    @State private var offset: Double = 0
    @State private var opacity: Double = 1
    @State private var scale: Double = 1
    @State private var blur: Double = 0
    
    @State private var rotation: Double = 0
    
    private func startFade() {
        withAnimation(.spring(duration: 2)) {
            self.offset = -600
            self.scale = 0.75
            self.opacity = 0
            self.blur = 3
        }
    }
    
//    MARK: AboutScreenEventViewBody
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .foregroundStyle(.clear)
                
                if isShowing {
                    makeEventView()
                        .border(.blue)
                        .transition(.blurReplace.combined(with: .scale))
                        .alignmentGuide(.leading) { _ in -position.x }
                        .alignmentGuide(.top) { _ in -position.y - offset }
                    
                        .opacity(opacity)
                        .scaleEffect(scale)
                        .blur(radius: blur)
                }
            }
            .task {
                await RecallModel.wait(for: relativeDelay)
                
                withAnimation(.spring) { isShowing = true }
            }
            .task {
                await RecallModel.wait(for: dissapearDelay)
                
                startFade()
            }
        }
    }
}
