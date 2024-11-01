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
    let peekHeight: Double = 0.9
    
    var isExpanded: Bool = true
    
    var canPullUp: Bool = false
    var canPullDown: Bool = false
    
    var progress: CGFloat = 1
    var mainOffset: CGFloat = 0
}

//MARK: PhotoScrollerView
@available(iOS 18.0, *)
struct PhotoScrollerView: View {
    
    var sharedData = PhotoScrollerViewModel()
    
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
        let minimisedHeight = screenHeight * sharedData.peekHeight
        let height = screenHeight - (minimisedHeight - (minimisedHeight * sharedData.progress))
        
        Rectangle()
            .foregroundStyle(.red)
            .scrollClipDisabled()
            .frame(height: height, alignment: .bottom)
    }
    
//    MARK: Body
    var body: some View {
        GeometryReader { geo in
            
            let screenHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            let minimisedHeight = (geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom) * sharedData.peekHeight
            let mainOffset = sharedData.mainOffset
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    
                    makeTopSpacer(in: screenHeight - 300)
                        .frame(width: geo.size.width)

                    VStack {
                        Text("hi there")
                        
                    }
                    .frame(minHeight: geo.size.height)
                }
                .offset(y: sharedData.canPullDown ? 0 : mainOffset < 0 ? -mainOffset : 0)
                .offset(y: mainOffset < 0 ? mainOffset : 0)
            }
            .onScrollGeometryChange(for: CGFloat.self, of: { geo in geo.contentOffset.y }) { oldValue, newValue in
                sharedData.mainOffset = newValue
            }
            
            .scrollDisabled(sharedData.isExpanded)
            .environment(sharedData)
            .gesture( makeGesture(minimisedHeight: minimisedHeight) )
        }
        .ignoresSafeArea(edges: .top)
    }
}

//MARK: Preview
@available(iOS 18.0, *)
#Preview {
    PhotoScrollerView()
}
