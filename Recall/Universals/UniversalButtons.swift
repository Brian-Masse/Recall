//
//  UniversalButtons.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI

//MARK: Rounded Buttons
struct RoundedButton: View {
    let label:  String
    let icon:   String
    let action: ()->Void
    let shrink: Bool
    
    init(label: String, icon: String, action: @escaping ()->Void, shrink: Bool = false) {
        self.label = label
        self.icon = icon
        self.action = action
        self.shrink = shrink
    }
    
    var body: some View {
        
        HStack {
            Spacer()
            Image(systemName: icon)
            Text(label)
//                .fixedSize()
//                .minimumScaleFactor( shrink ? 0.5 : 1 )
                .lineLimit(1)
            Spacer()
        }
        
        .padding(.horizontal)
        .padding(.vertical, 7)
        .rectangularBackgorund(rounded: true)
        .onTapGesture { action() }
    }
}

struct AsyncRoundedButton: View {
    let label: String
    let icon: String
    let action: () async -> Void
    
    @State var running: Bool = false
    
    var body: some View {
        ZStack {
            RoundedButton(label: label, icon: icon, action: { running = true })
            if running {
                ProgressView()
                    .task {
                        await action()
                        running = false
                    }
            }
        }
    }
}

//MARK: ShortRoundedButton
struct ShortRoundedButton: View {
    
    let label: String
    let completedLabel: String
    let icon: String
    let completedIcon: String
    
    let completed: () -> Bool
    let action: () -> Void
    
    @State var tempCompletion: Bool = false
    
    init( _ label: String, to completedLabel: String = "", icon: String, to completedIcon: String = "", completed: @escaping () -> Bool = {false}, action: @escaping () -> Void ) {
        self.label = label
        self.completedLabel = completedLabel
        self.icon = icon
        self.completedIcon = completedIcon
        self.completed = completed
        self.action = action
    }
    
    var body: some View {
        let label: String = (self.completed() || tempCompletion ) ? completedLabel : label
        let completedIcon: String = (self.completed() || tempCompletion ) ? completedIcon : icon
        
        HStack {
            if label != "" {
                Text(label)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
//            UniversalText(label, size: Constants.UIDefaultTextSize, true)
            Image(systemName: completedIcon)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .rectangularBackgorund(rounded: true)
        .animation(.default, value: completed() )
        .onTapGesture { action() }
    }
}

struct asyncShortRoundedButton: View {
    
    let label: String
    let icon: String
    let action: () async -> Void
    
    @State var running: Bool = false
    
    var body: some View {
        ZStack {
            ShortRoundedButton(label, icon: icon) { running = true }
            if running {
                ProgressView()
                    .task {
                        await action()
                        running = false
                    }
            }
        }
    }
    
}

//MARK: LargeFormRoundedButton
struct LargeFormRoundedButton: View {
    
    let label: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        
        HStack {
            Spacer()
            Image(systemName: icon)
            UniversalText(label, size: Constants.UIDefaultTextSize, lighter: true)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 40)
        .rectangularBackgorund()
        .onTapGesture { action() }
        
    }
}

//MARK: LargeRoundedButton
struct LargeRoundedButton: View {
    
    let label: String
    let completedLabel: String
    let icon: String
    let completedIcon: String
    
    let completed: () -> Bool
    let action: () -> Void
    
    let small: Bool 
    let wide: Bool
    let color: Color?
    
    @State var tempCompletion: Bool = false
    
    init( _ label: String, to completedLabel: String = "", icon: String, to completedIcon: String = "", wide: Bool = false, small: Bool = false, color: Color? = nil, completed: @escaping () -> Bool = {false}, action: @escaping () -> Void ) {
        self.label = label
        self.completedLabel = completedLabel
        self.icon = icon
        self.completedIcon = completedIcon
        self.completed = completed
        self.action = action
        self.wide = wide
        self.small = small
        self.color = color
    }
    
    var body: some View {
        let label: String = (self.completed() || tempCompletion ) ? completedLabel : label
        let completedIcon: String = (self.completed() || tempCompletion ) ? completedIcon : icon
        
        HStack {
            if wide { Spacer() }
            if label != "" {
                UniversalText(label, size: Constants.UISubHeaderTextSize, font: .syneHeavy)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            
            if completedIcon != "" {
                Image(systemName: completedIcon)
            }
            if wide { Spacer() }
        }
        .padding(.vertical, small ? 7: 25 )
        .padding(.horizontal, small ? 25 : 25)
        .foregroundColor(.black)
        .background( color == nil ? Colors.tint : color )
        .cornerRadius(Constants.UIDefaultCornerRadius)
        .animation(.default, value: completed() )
        .onTapGesture { action() }
    }
}
