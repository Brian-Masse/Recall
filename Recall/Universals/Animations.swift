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


struct LogoAnimation: View {
    @State var imageName: String = ""
    @State var inReverse: Bool = false

    private func timer() {
        var index = 1
        let _ = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { (Timer) in
            
            imageName = "logoAnimation\( min(max(index, 1), 40) )"
            
            index += inReverse ? -1 : 1
            
            if (index > 50){
                inReverse = true
            }
            if (index < -10) {
                index = 1
                inReverse = false
            }
        }
    }
    
    var body: some View {
        Image( imageName )
            .resizable()
            .renderingMode(.template)
            .universalTextStyle()
//            .universalStyledBackgrond(., onForeground: true)

            .frame(width: 100, height: 100)
            .onAppear { timer() }
    }
    
}


#Preview {
    LogoAnimation()
}
