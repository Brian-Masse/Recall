//
//  ViewModifiers.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

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

public struct UniversalTexts: View {
    let text: String
    let size: CGFloat
    let font: String
    let textCase: Text.Case?
    
    let wrap: Bool
    let fixed: Bool
    let scale: Bool
    
    let alignment: TextAlignment
    let lineSpacing: CGFloat
    let compensateForEmptySpace: Bool
    
    public init(_ text: String,
                size: CGFloat,
                font: UniversalFont = FontProvider[.madeTommyRegular],
                case textCase: Text.Case? = nil,
                wrap: Bool = true,
                fixed: Bool = false,
                scale: Bool = false,
                textAlignment: TextAlignment = .leading,
                lineSpacing: CGFloat = 0.5,
                compensateForEmptySpace: Bool = true
    ) {
        self.text = text
        self.size = size
        self.font = font.postScriptName
        self.textCase = textCase
        
        self.wrap = wrap
        self.fixed = fixed
        self.scale = scale
        
        self.alignment = textAlignment
        self.lineSpacing = lineSpacing
        self.compensateForEmptySpace = compensateForEmptySpace
    }
    
    @ViewBuilder
    private func makeText(_ text: String) -> some View {
        Text(text)
            .lineSpacing(lineSpacing)
            .minimumScaleFactor(scale ? 0.1 : 1)
            .lineLimit(wrap ? 30 : 1)
            .multilineTextAlignment(alignment)
            .font( Font.custom(font, size: size) )
            .if( textCase != nil ) { view in view.textCase(textCase) }
        
    }
    
    private func translateTextAlignment() -> HorizontalAlignment {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
    
    public var body: some View {
        
        if lineSpacing < 0 {
            let texts = text.components(separatedBy: "\n")
            
            VStack(alignment: translateTextAlignment(), spacing: 0) {
                ForEach(0..<texts.count, id: \.self) { i in
                    makeText(texts[i])
                        .offset(y: CGFloat( i ) * lineSpacing )
                }
            }
            .padding(.bottom, (Double(texts.count - 1) * lineSpacing) )
        } else {
            makeText(text)
        }
    }
}
