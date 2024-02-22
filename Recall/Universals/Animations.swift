//
//  Animations.swift
//  Recall
//
//  Created by Brian Masse on 7/30/23.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: Animtable Modifiers

struct SlideState: AnimatableModifier {
    
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
    }
}

extension AnyTransition {
    
    enum SlideDirection {
        case left
        case right
        case none
    }
    
    static func slideAwayTransition(_ slideDirection: SlideDirection = .right) -> AnyTransition {
        
        let toRight = AnyTransition.modifier(active: SlideState( offset: 400), identity: SlideState(offset: 0))
        let fromRight = AnyTransition.modifier(active: SlideState( offset: -400 ), identity: SlideState(offset: 0))
        
        switch slideDirection {
        case .right: return AnyTransition.asymmetric(insertion: toRight, removal: fromRight)
        case .left: return AnyTransition.asymmetric(insertion: fromRight, removal: toRight)
        default: return .identity
        }
    }
}


struct LoadingView: View {
    
    @Environment( \.colorScheme ) var colorScheme
    
    static let width: CGFloat = 450
    static let blur: CGFloat = 35
    
    let height: CGFloat
    
    @State var offset: CGFloat = LoadingView.startingOffset
    
    //    MARK: Class Methods
    private func beginAnimation(_ width: CGFloat) {
        self.offset = LoadingView.startingOffset
        withAnimation { self.offset = width }
    }
    
    private static var startingOffset: CGFloat {
        -LoadingView.width - (LoadingView.blur * 2)
    }
    
    private var secondaryStyle: UniversalStyle {
        colorScheme == .dark ? .transparent : .primary
    }
    
    private var highlightColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    //    MARK: ViewBuilders
    @ViewBuilder
    private func makeGradient(facingRight: Bool) -> some View {
        LinearGradient(stops: [.init(color: highlightColor.opacity(0.2), location: 0.55),
                               .init(color: .clear, location: 1)],
                       startPoint: facingRight ? .leading : .trailing,
                       endPoint: facingRight ? .trailing : .leading)
    }
    
    @ViewBuilder
    private func makeBlur() -> some View {
        HStack(spacing: 0) {
            makeGradient(facingRight: false)
            makeGradient(facingRight: true)
        }
        .blur(radius: LoadingView.blur)
        .scaleEffect(x: 0.9)
    }
    
    //    MARK: Body
    var body: some View {
        HStack(alignment: .top) {
            UniversalText("Hello, this is a secret message",
                          size: Constants.UIDefaultTextSize, wrap: false)
            .foregroundStyle(.clear)
            .rectangularBackground(7, style: secondaryStyle, cornerRadius: 10)
            
            UniversalText("hi :)",
                          size: Constants.UIDefaultTextSize, wrap: false)
            .foregroundStyle(.clear)
            .rectangularBackground(7, style: secondaryStyle, cornerRadius: 10)
            
            Spacer()
            
            Rectangle()
                .foregroundStyle(.clear)
                .frame(width: 10, height: height - 30)
            
            UniversalText("hello",
                          size: Constants.UIDefaultTextSize, wrap: false)
            .foregroundStyle(.clear)
            .rectangularBackground(7, style: secondaryStyle, cornerRadius: 10)
        }
        .padding()
        .overlay { GeometryReader { geo in
            makeBlur()
                .frame(width: LoadingView.width)
                .offset(x: offset)
                .opacity(0.5)
                .animation(Animation
                    .easeInOut(duration: 2)
                    .delay(0.6)
                    .repeatForever(autoreverses: false),
                           value: offset)
                .onAppear { beginAnimation(geo.size.width + LoadingView.blur) }
        }}
        .rectangularBackground(0, style: .secondary)
    }
}

//MARK: CollectionLoadingView
struct CollectionLoadingView: View {
    let count: Int
    let height: CGFloat
    
    var body: some View {
        VStack {
            ForEach( 0..<count, id: \.self ) { _ in
                LoadingView(height: height)
            }
        }
    }
}
