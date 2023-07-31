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
    let scale: Bool
    
    init(_ text: String, size: CGFloat, font: ProvidedFont = .helvetica, wrap: Bool = true, lighter: Bool = false, _ bold: Bool = false, fixed: Bool = false, scale: Bool = false) {
        self.text = text
        self.size = size
        self.bold = bold
        self.wrap = wrap
        self.lighter = lighter
        self.fixed = fixed
        self.scale = scale
        self.font = font.rawValue
    }
    
    var body: some View {
        
        Text(text)
            .dynamicTypeSize( ...DynamicTypeSize.accessibility1 )
            .lineSpacing(0.5)
            .minimumScaleFactor(scale ? 0.5 : 1)
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

struct WrappedHStack<Content: View, Object: Identifiable>: View where Object: Equatable {
    
    @State var size: CGSize = .zero
    
    let collection: [Object]
    let content: ( Object ) -> Content
    let spacing: CGFloat

    init( collection: [Object], spacing: CGFloat = 10,  @ViewBuilder content: @escaping (Object) -> Content ) {
        self.collection = collection
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var previousRowHeight: CGFloat = 0
        
        GeometryReader { geo in
            SubViewGeometryReader(size: $size) {
                ZStack(alignment: .leading) {
                    ForEach( collection ) { object in
                        
                        content(object)
                            .alignmentGuide(HorizontalAlignment.leading) { d in
                                if abs(geo.size.width + width) < d.width {
                                    width = 0
                                    height -= (previousRowHeight + spacing)
                                    previousRowHeight = 0
                                }
                                previousRowHeight = max(d.height, previousRowHeight)
                                let offSet = width
                                if collection.last == object { width = 0 }
                                else { width -= (d.width + spacing) }
                                
                                return offSet
                            }
                            .alignmentGuide(VerticalAlignment.center) { d in
                                let offset = height + (d.height / 2)
                                if collection.last == object { height = 0 }
                                
                                return offset
                            }
                    }
                }
            }
        }
        .frame(height: size.height)
    }
}

struct SubViewGeometryReader<Content: View>: View {
    @Binding var size: CGSize
    let content: () -> Content
    var body: some View {
        ZStack {
            content()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: proxy.size)
                    }
                )
        }
        .onPreferenceChange(SizePreferenceKey.self) { preferences in
            self.size = preferences
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: Value = .zero

    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

//MARK: HeadedBackground

struct HeadedBackground<C1: View, C2: View>: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let headerView: C1
    let content: C2
    
    init( @ViewBuilder headerBuilder: () -> C1, @ViewBuilder content: () -> C2 ) {
        self.headerView = headerBuilder()
        self.content = content()
    }
    
    var body: some View {
        
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(Colors.tint)
                    .frame(height: 60)
                    .cornerRadius(Constants.UILargeCornerRadius, corners: [.topLeft, .topRight])
                    .cornerRadius(Constants.UIDefaultCornerRadius, corners: [.bottomLeft, .bottomRight])
                
                headerView
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            }
            
            content
            
        }
        .background( colorScheme == .dark ? .black : .white )
        .cornerRadius(Constants.UILargeCornerRadius)
        .padding(7)
        
    }
}

//MARK: CircularProgressBar

struct CircularProgressView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let currentValue: Float
    let totalValue: Float
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    colorScheme == .dark ? .black : .white,
                    lineWidth: Constants.UICircularProgressWidth
                )
            Circle()
                .trim(from: 0, to: CGFloat(currentValue / totalValue) )
                .stroke(
                    Colors.tint,
                    style: StrokeStyle(
                        lineWidth: Constants.UICircularProgressWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
            
            VStack {
                UniversalText("\(Int(currentValue)) / \(Int(totalValue))", size: Constants.UIHeaderTextSize, font: Constants.titleFont, true)
                    .padding(.bottom, 5)
                UniversalText("\(((currentValue / totalValue) * 100).round(to: 2)  )%", size: Constants.UIDefaultTextSize, font: Constants.mainFont)
            }
        }
    }
}
