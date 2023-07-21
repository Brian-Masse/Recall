//
//  UIUniversals.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import Charts

enum ProvidedFont: String {
    case renoMono = "RenoMono-Regular"
    case helvetica = "helvetica"
    case syneHeavy = "Syne-Bold"
    
}

//MARK: UniversalText
struct UniversalText: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let text: String
    let size: CGFloat
    let bold: Bool
    let wrap: Bool
    let lighter: Bool
    let fixed: Bool
    let font: String
    
    init(_ text: String, size: CGFloat, font: ProvidedFont = .helvetica, wrap: Bool = true, lighter: Bool = false, _ bold: Bool = false, fixed: Bool = false) {
        self.text = text
        self.size = size
        self.bold = bold
        self.wrap = wrap
        self.lighter = lighter
        self.fixed = fixed
        self.font = font.rawValue
    }
    
    var body: some View {
        
        Text(text)
            .dynamicTypeSize( ...DynamicTypeSize.accessibility1 )
    
            .lineSpacing(5)
            .minimumScaleFactor(wrap ? 1 : 0.5)
            .lineLimit(wrap ? 10 : 1)
            .font( fixed ? Font.custom(font, fixedSize: size) : Font.custom(font, size: size) )
            .bold(bold)
            .opacity(lighter ? 0.8 : 1)
    }
}

//MARK: ResizeableIcon
struct ResizeableIcon: View {
    let icon: String
    let size: CGFloat
    
    var body: some View {
        Image(systemName: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: size)
    }
}

//MARK: AsyncLoader
struct AsyncLoader<Content>: View where Content: View {
    @Environment(\.scenePhase) private var scenePhase
    
    let block: () async -> Void
    let content: Content
    
    @State var loading: Bool = true
    
    init( block: @escaping () async -> Void, @ViewBuilder content: @escaping () -> Content ) {
        self.content = content()
        self.block = block
    }

    var body: some View {
        VStack{
            if loading {
                ProgressView() .task {
                        await block()
                        loading = false
                    }
            } else if scenePhase != .background && scenePhase != .inactive { content }
        }
        .onBecomingVisible { loading = true }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active { loading = true }
        }
    }
}
