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
class PhotoScrollerViewModel {
    let restHeight: Double = 0.6
    let peekHeight: Double = 0.92
    
    var isExpanded: Bool
    
    var canPullUp: Bool = false
    var canPullDown: Bool = false
    
    var progress: CGFloat
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
    
    init( startExpanded: Bool, @ViewBuilder headerContent: () -> C1, @ViewBuilder bodyContent: () -> C2 ) {
        self.headerContent = headerContent()
        self.bodyContent = bodyContent()
        
        self.sharedData = PhotoScrollerViewModel(startExpanded: startExpanded)
    }
    
//    MARK: Gesture
    private func makeGesture(minimisedHeight: Double) -> PhotoScrollerSimultaneousGesture {
        PhotoScrollerSimultaneousGesture(isEnabled: true) { gesture in
            
            let state = gesture.state
            let translation = gesture.translation(in: gesture.view).y
            let isScrolling = state == .began || state == .changed
            
            if state == .began {
                sharedData.canPullDown = translation > -10 && sharedData.mainOffset < 5
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
                    }
                }
            }
        }
    }
    
//    MARK: TopSpacer
    @ViewBuilder
    private func makeTopSpacer(in screenHeight: Double) -> some View {
        let fullHeight = screenHeight * sharedData.restHeight
        let minimisedHeight: Double = screenHeight - screenHeight * sharedData.peekHeight
        let height = minimisedHeight + ( fullHeight - minimisedHeight ) * sharedData.progress
        
        Rectangle()
            .foregroundStyle(.clear)
            .scrollClipDisabled()
            .frame(height: height, alignment: .bottom)
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            
            let screenHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            let minimisedHeight = (geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom) * sharedData.peekHeight
//            let mainOffset = sharedData.mainOffset
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    
                    ZStack(alignment: .leading) {
                        makeTopSpacer(in: screenHeight)
                            .frame(width: geo.size.width)
                        
                        headerContent
                            .gesture(DragGesture(), including: .none)
                    }

                    bodyContent
                        .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                }
//                .offset(y: sharedData.canPullDown ? 0 : mainOffset < 0 ? -mainOffset : 0)
//                .offset(y: mainOffset < 0 ? mainOffset : 0)
            }
            .onScrollGeometryChange(for: CGFloat.self, of: { geo in geo.contentOffset.y }) { oldValue, newValue in
                sharedData.mainOffset = newValue
            }
            
            .scrollDisabled(sharedData.isExpanded)
            .environment(sharedData)
            .gesture( makeGesture(minimisedHeight: minimisedHeight) )
        }
        .ignoresSafeArea(edges: .bottom)
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
                
                
                PhotoScrollerView(startExpanded: false) {
                    Text("hi there")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                    
                } bodyContent: {
                    VStack {
                        ForEach( 0...20, id: \.self ) { i in
                            Rectangle()
                                .foregroundStyle(.green)
                                .frame(height: 40)
                        }
                    }
                    .padding()
                    .clipShape(RoundedRectangle( cornerRadius: Constants.UILargeCornerRadius ))
                    .background {
                        RoundedRectangle( cornerRadius: Constants.UILargeCornerRadius )
                            .foregroundStyle(.background)
                    }
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
