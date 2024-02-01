//
//  ViewModifiers.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift

private struct Developer: ViewModifier {
    func body(content: Content) -> some View {
        if inDev {
            content
        }
    }
}

//MARK: Transitions
private struct SlideTransition: ViewModifier {
    func body(content: Content) -> some View {
        content
            .transition(.push(from: .trailing))
    }
}

//MARK: Extension
extension View {
    func developer() -> some View {
        modifier( Developer() )
    }
    
    func slideTransition() -> some View {
        modifier( SlideTransition() )
    }
}
