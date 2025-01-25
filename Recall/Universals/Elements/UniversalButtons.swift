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
    
    let action: (() -> Void)?
    let asyncAction: (() async -> Void)?
    let isAsync: Bool
    
    init( _ icon: String, label: String = "", fullWidth: Bool = false, action: @escaping () -> Void ) {
        self.icon = icon
        self.title = label
        self.full = fullWidth
        self.action = action
        self.asyncAction = nil
        self.isAsync = false
    }
    
    init( _ icon: String, label: String = "", fullWidth: Bool = false, action: @escaping () async -> Void ) {
        self.icon = icon
        self.title = label
        self.full = fullWidth
        self.action = nil
        self.asyncAction = action
        self.isAsync = true
    }
    
    var body: some View {
        UniversalButton(labelBuilder: {
            HStack {
                if full { Spacer() }
                
                if !title.isEmpty {
                    UniversalText( title, size: Constants.UIDefaultTextSize + 2, font: Constants.mainFont )
                        .padding(.trailing, 5)
                }
                
                RecallIcon(icon, bold: false)
                
                if full { Spacer() }
            }
            .rectangularBackground(style: .secondary)
        },
                        action: isAsync ? asyncAction! : action!)

    }
}

//MARK: DissmissButton
struct DismissButton: View {
    
    @Environment( \.dismiss ) var dismiss
    
    private var onSubmit: (() -> Void)?
    
    init( onSubmit: (() -> Void)? = nil ) {
        self.onSubmit = onSubmit
    }
    
    private var icon: String {
        if #available(iOS 18.0, *) {
            return "chevron.down"
        } else {
            return "chevron.left"
        }
    }
    
    var body: some View {
        UniversalButton {
            HStack {
                RecallIcon( icon )
                    .frame(width: 10)
            }
            .frame(height: 10)
            .font(.callout)
            .rectangularBackground(12, style: .transparent)
        } action: {
            if let onSubmit {
                onSubmit()
            } else {
                dismiss()
            }
        }
    }
}
