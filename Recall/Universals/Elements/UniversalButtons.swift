//
//  UniversalButtons.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: ConditionalLargeRoundedButton
struct ConditionalLargeRoundedButton: View {
    
    let title: String
    let icon: String
    
    let wide: Bool
    let allowTapOnDisabled: Bool
    
    let condition: () -> Bool
    let action: () -> Void
    
    init( title: String, icon: String, wide: Bool = true, allowTapOnDisabled: Bool = false, condition: @escaping () -> Bool, action: @escaping () -> Void ) {
        self.title = title
        self.icon = icon
        self.wide = wide
        self.allowTapOnDisabled = allowTapOnDisabled
        self.condition = condition
        self.action = action
    }
    
    var body: some View {
        HStack {
            if wide { Spacer() }
            if title != "" { UniversalText(title, size: Constants.UISubHeaderTextSize, font: Constants.titleFont) }
            RecallIcon(icon)
            if wide { Spacer() }
            
        }
            .padding(10)
            .if( condition() ) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
            .if( !condition() ) { view in view.rectangularBackground(style: .secondary) }
            .onTapGesture { withAnimation {
                if condition() || allowTapOnDisabled { action() }
            }}
    }
}

//MARK: IconButton
struct IconButton: View {
    
    let title: String
    let icon: String
    
    let full: Bool
    let action: () -> Void
    
    init( _ icon: String, label: String = "", fullWidth: Bool = false, action: @escaping () -> Void ) {
        self.icon = icon
        self.title = label
        self.full = fullWidth
        self.action = action
    }
    
    var body: some View {
        UniversalButton {
            HStack {
                if full { Spacer() }
                
                if !title.isEmpty {
                    UniversalText( title, size: Constants.UIDefaultTextSize + 2, font: AndaleMono.shared )
                        .padding(.trailing, 5)
                }
                
                RecallIcon(icon, bold: false)
                
                if full { Spacer() }
            }
            .rectangularBackground(style: .secondary)
            
        } action: { action() }
    }
}
