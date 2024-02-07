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


struct LoadingRectangle: View {
    
    @Environment( \.colorScheme ) var colorScheme
    
    static let width: CGFloat = 200
    static let blur: CGFloat = 100
    
    let height: CGFloat
    
    @State var offset: CGFloat = -LoadingRectangle.width - (LoadingRectangle.blur * 2)
    @State var shouldAnimate: Bool = true
    
    private func beginAnimation(_ width: CGFloat) {
        self.offset = -LoadingRectangle.width
        withAnimation { self.offset = width }
    }
    
    private var secondaryStyle: UniversalStyle {
        colorScheme == .dark ? .transparent : .primary
    }
    
    var body: some View {
        
        HStack(alignment: .top) {
            
            UniversalText("Hello, this is a secret message",
                          size: Constants.UIDefaultTextSize, wrap: false)
            .foregroundStyle(.clear)
            .rectangularBackground(7, style: secondaryStyle, cornerRadius: 10)
            
            UniversalText("so :)",
                          size: Constants.UIDefaultTextSize, wrap: false)
            .foregroundStyle(.clear)
            .rectangularBackground(7, style: secondaryStyle, cornerRadius: 10)
            
            Spacer()
            
            Rectangle()
                .foregroundStyle(.clear)
                .frame(width: 10, height: height)
            
            UniversalText("so :)",
                          size: Constants.UIDefaultTextSize, wrap: false)
            .foregroundStyle(.clear)
            .rectangularBackground(7, style: secondaryStyle, cornerRadius: 10)
        }
        .overlay { GeometryReader { geo in
            Rectangle()
                .universalTextStyle(reversed: false)
                .frame(width: LoadingRectangle.width)
                .blur(radius: LoadingRectangle.blur)
                .opacity(0.4)
                .offset(x: offset)
                .animation(Animation
                    .easeInOut(duration: 2)
                    .delay(0.6)
                    .repeatForever(autoreverses: false),
                           value: offset)
                .onAppear { beginAnimation(geo.size.width + LoadingRectangle.blur * 2) }
        }}
        .rectangularBackground(style: .secondary)
    }
}

struct LoadingPageView: View {
    
    let count: Int
    let height: CGFloat
    
    var body: some View {
        
        VStack {
            ForEach( 0..<count, id: \.self ) { _ in
                LoadingRectangle(height: height)
            }
        }
    }
}

#Preview(body: {
    LoadingPageView(count: 3, height: 100)
})

