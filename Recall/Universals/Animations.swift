//
//  Animations.swift
//  Recall
//
//  Created by Brian Masse on 7/30/23.
//

import Foundation
import SwiftUI

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
