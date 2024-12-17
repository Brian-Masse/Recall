//
//  RecallUniversals.swift
//  Recall
//
//  Created by Brian Masse on 12/19/24.
//

import Foundation
import SwiftUI
import UIUniversals

//    MARK: - sectionHeader
@ViewBuilder
func makeSectionHeader(
    _ icon: String,
    title: String,
    fillerMessage: String = "",
    isActive: Bool = true,
    fillerAction: (() -> Void)? = nil
) -> some View {
    if isActive {
        HStack {
            RecallIcon(icon)
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            
            Spacer()
        }
        .padding(.leading)
        .opacity(0.75)
    } else {
        makeSectionFiller(icon: icon, message: fillerMessage, action: fillerAction)
    }
}


//    MARK: makeSectionFiller
@ViewBuilder
private func makeSectionFiller(icon: String, message: String, action: (() -> Void)?) -> some View {
    UniversalButton {
        VStack {
            HStack { Spacer() }
            
            RecallIcon( icon )
                .padding(.bottom, 5)
            
            UniversalText( message, size: Constants.UIDefaultTextSize, font: Constants.mainFont, textAlignment: .center )
                .opacity(0.75)
        }
        .opacity(0.75)
        .rectangularBackground(style: .secondary)
        
    } action: { if let action { action() }}
}
