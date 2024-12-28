//
//  PhotoScrollerView.swift
//  Recall
//
//  Created by Brian Masse on 10/30/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: PhotoScrollViewModel
@Observable
final class PhotoScrollerViewModel: Sendable {
    let restHeight: Double = 0.5
    let peekHeight: Double = 0.92
    
    var isExpanded: Bool
    
    var canPullUp: Bool = false
    var canPullDown: Bool = false
    
    var progress: CGFloat
    var previousOffset: CGFloat = 0
    var mainOffset: CGFloat = 0
    
    init(startExpanded: Bool) {
        self.isExpanded = !startExpanded
        self.progress = startExpanded ? 0 : 1
    }
}

//MARK: PhotoScrollerView
@available(iOS 18.0, *)
struct PhotoScrollerView<C1: View, C2: View>: View {
    
    var sharedData: PhotoScrollerViewModel
    
    let headerContent: C1
    let bodyContent: C2
    
    let allowsScroll: Bool
    
    init( startExpanded: Bool, allowsScrolling: Bool = true, @ViewBuilder headerContent: () -> C1, @ViewBuilder bodyContent: () -> C2 ) {
        self.headerContent = headerContent()
        self.bodyContent = bodyContent()
        
        self.allowsScroll = allowsScrolling
        self.sharedData = PhotoScrollerViewModel(startExpanded: startExpanded)
    }
    
//    MARK: Gesture
    private func makeGesture(minimisedHeight: Double) -> PhotoScrollerSimultaneousGesture {
        PhotoScrollerSimultaneousGesture(isEnabled: true) { gesture in
            
            if !allowsScroll { return }
            
            let state = gesture.state
            let translation = gesture.translation(in: gesture.view).y
            let isScrolling = state == .began || state == .changed
            
            if state == .began {
                sharedData.canPullDown = translation > -10 && sharedData.mainOffset < 20
                sharedData.canPullUp = translation < 10
            }
            
            if isScrolling {
                if sharedData.canPullDown && !sharedData.isExpanded {
                    let progress = max(min(translation / minimisedHeight, 1), 0)
                    sharedData.progress = progress
                }
                
                if sharedData.canPullUp && sharedData.isExpanded {
                    let progress = max(min(-translation / minimisedHeight, 1), 0)
                    sharedData.progress = 1 - progress
                }
                
            } else {
                withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                    if sharedData.canPullDown && !sharedData.isExpanded && translation > 0 {
                        sharedData.isExpanded = true
                        sharedData.progress = 1
                    }
                    
                    if sharedData.canPullUp && sharedData.isExpanded && translation < 0 {
                        sharedData.isExpanded = false
                        sharedData.progress = 0
                        
                        scrollPosition.scrollTo(y: 20)
                    }
                }
                
                sharedData.previousOffset = sharedData.mainOffset
            }
        }
    }
    
//    MARK: TopSpacer
    @ViewBuilder
    private func makeTopSpacer(in screenHeight: Double) -> some View {
        let fullHeight = screenHeight * sharedData.restHeight
        let minimisedHeight: Double = screenHeight - screenHeight * sharedData.peekHeight
        let height = minimisedHeight + ( fullHeight - minimisedHeight ) * sharedData.progress
        
        headerContent
            .frame(height: height, alignment: .bottom)
    }
    
//    MARK: ContentMask
    private struct ContentMask: Shape {
        let screenHeight: Double
        var sharedData: PhotoScrollerViewModel
        
        func path(in rect: CGRect) -> Path {
            let restHeight = rect.size.height - screenHeight * (sharedData.restHeight)
            let fullheight = screenHeight * sharedData.peekHeight
            let height = (!sharedData.isExpanded ? fullheight : restHeight) + 100
            
            let offset = rect.size.height - height
            
            let newRect = CGRect(x: 0,
                              y: offset,
                              width: rect.size.width,
                              height: height)
            
            return Path(newRect)
        }
    }

    @State private var baseScrollOffset: Double = 0
    @State private var scrollPosition = ScrollPosition()
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            
            let screenHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            let minimisedHeight = (geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom) * sharedData.peekHeight
            
            VStack(spacing: 10) {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 10) {
                        
//                        This adds a minor scroll ontop of the main scroll
//                        so when pulling down it overrides any other gestures
//                        namely the navigation(.zoom) swipe transition
                        if allowsScroll && !sharedData.isExpanded && sharedData.mainOffset <= (baseScrollOffset + 20) {
                            Rectangle()
                                .frame(height: 20)
                                .foregroundStyle(.clear)
                                .onAppear { withAnimation { scrollPosition.scrollTo(y: 20) }}
                        }
                        
                        makeTopSpacer(in: screenHeight)
                        
                        bodyContent
                            .frame(minHeight: geo.size.height, alignment: .top)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.UILargeCornerRadius))
                    }
                }
                .animation(.easeInOut, value: sharedData.mainOffset)
                .scrollPosition($scrollPosition)
                .gesture( makeGesture(minimisedHeight: minimisedHeight) )
                .onScrollGeometryChange(for: CGFloat.self, of: { geo in geo.contentOffset.y }) { oldValue, newValue in
                    if baseScrollOffset == 0 { self.baseScrollOffset = newValue }
                    sharedData.mainOffset = newValue
                }
                .scrollDisabled(sharedData.isExpanded || sharedData.mainOffset < baseScrollOffset )
                .clipShape(RoundedRectangle(cornerRadius: Constants.UILargeCornerRadius))
                .safeAreaPadding(7)
                .ignoresSafeArea(edges: .bottom)
            }
        }
//        .overlay {
//            VStack {
//                Text("progress: \(sharedData.progress)")
//                Text("base offset: \(baseScrollOffset)")
//                Text("mainoffset: \(sharedData.mainOffset)")
//            }
//            .background(.red)
//        }
    }
}

//MARK: test
@available(iOS 18.0, *)
struct TestPhotoScrollerView: View {
    
    var body: some View {
        GeometryReader { geo in
            
            ZStack(alignment: .top) {
                Image("sampleImage1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .frame(width: geo.size.width, height: geo.size.height * 0.8)
                    .contentShape(Rectangle())
                    .opacity(0.25)
//
                PhotoScrollerView(startExpanded: false) {
                    Text("hi there")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                    
                } bodyContent: {
                    VStack(spacing: 10) {
                        ForEach( 0...10, id: \.self ) { i in
                            Rectangle()
                                .foregroundStyle(.green)
                                .frame(height: 40)
                                .overlay {
                                    Text( "\(geo.size.height)" )
                                }
                        }
                    }
                    .border(.green)
                    .padding()
                    .background(.red)
//                    .clipShape(RoundedRectangle( cornerRadius: Constants.UILargeCornerRadius ))
                }
            }
        }
    }
}

//MARK: Preview
@available(iOS 18.0, *)
#Preview {
//    PhotoScrollerView()
    TestPhotoScrollerView()
}
