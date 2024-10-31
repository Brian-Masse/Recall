//
//  PhotoScrollerView.swift
//  Recall
//
//  Created by Brian Masse on 10/30/24.
//

import Foundation
import SwiftUI
import UIUniversals

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

@available(iOS 18.0, *)
struct PhotoScrollerView<C1: View, C2: View>: View {

    private let headerContent: C1
    private let bodyContent: C2
    
    init( @ViewBuilder headerContent: () -> C1, @ViewBuilder bodyContent: () -> C2 ) {
        self.headerContent = headerContent()
        self.bodyContent = bodyContent()
    }
    
    @State private var scrollPosition: ScrollPosition = ScrollPosition()
    @State private var velocity: CGFloat = 0
    @State private var scrollPhase: ScrollPhase = .idle
    
    @State private var offset: CGFloat = 0
    
    private let coordinateSpaceName: String = "photoScrollerCoordinateSpace"
    private let headerName: String = "header"
    
    private func makeScrollSnapping(in geo: GeometryProxy, proxy: ScrollViewProxy) {
        if offset > 100 /*&& offset < geo.size.height * 0.5*/ {
//            scrollPosition.scrollTo(y: 400)
            
////            proxy.scrollTo("body", anchor: .top)
        } else if offset >= -100 {
//            scrollPosition.scrollTo(id: headerName)
        }
    }
    
//    MARK: Header
    @ViewBuilder
    private func makeHeader(in geo: GeometryProxy) -> some View {
        ZStack {
            Image( "sampleImage1" )
                .resizable()
                .aspectRatio(contentMode: .fill)
//                .scaleEffect(1.2 + (max(scrollOfset.y - 100, 0) / 800), anchor: .top)
            
            headerContent
        }
        .frame(height: geo.size.height * (3/5))
        .id(headerName)
        .offset(y: offset)
    }
    
    private func scrollToContent() {
        scrollPosition.scrollTo(y: scrollThreshold + 62)
    }
    
    private func scrollToHeader() {
        scrollPosition.scrollTo(edge: .top)
    }
    
    private let velocityThreshold: Double = 40
    private let scrollThreshold: Double = 400
    
//    MARK: Body
    var body: some View {
        
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
//                        makeHeader(in: geo)
//                            .scrollTargetLayout()
                        
                        Rectangle()
                            .foregroundStyle(.red)
                            .frame(height: geo.size.height * (3/5))
                            
                        VStack(alignment: .leading, spacing: 10) {
                            HStack { Spacer() }
                            
                            bodyContent
                        }
                        .padding()
                        .frame(minHeight: geo.size.height + 100, alignment: .top)
                        .background(alignment: .top) {
                            UnevenRoundedRectangle(cornerRadii: .init(topLeading: Constants.UILargeCornerRadius,
                                                                      topTrailing: Constants.UILargeCornerRadius) )
                            .foregroundStyle(.blue)
                        }
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .foregroundStyle(.white)
                                .frame(height: 200)
                                .offset(y: 200)
                        }
                        .padding(.top)
                        .id("body")
                        .scrollTargetLayout()
                    }
                    .coordinateSpace(name: coordinateSpaceName)
                    
                    .onChange(of: offset) { oldVal, newVal in
                        
                        if offset > scrollThreshold { return }
                        
//                        if scrollPhase == .idle || scrollPhase == .decelerating {
                            self.velocity = newVal - oldVal
                            
                            if velocity < -10 {
                                scrollToHeader()
                                print("to header")
                            } else if velocity > 10 {
                                scrollToContent()
                                print("to content")
                                
                            }
//                        }
                        
                    }

                }
                .scrollPosition($scrollPosition)
                .animation(.linear(duration: 0), value: scrollPosition)
                
                .onScrollGeometryChange(for: CGPoint.self, of: { geo in geo.contentOffset }, action: { oldValue, newValue in
                    self.offset = newValue.y
                })
                
                
                .overlay {
                    VStack {
                        Text("\(offset)")
                        Text("\(velocity)")
                        Text("\(geo.size.height * 0.2)")
                    }
                }
                .onScrollPhaseChange { oldPhase, newPhase, context in

                    self.scrollPhase = newPhase
                    if oldPhase == .idle { return }
                    if oldPhase == .interacting && newPhase == .animating { return }
                    
//                    if abs(self.velocity) > velocityThreshold {
//                        self.velocity = 0
//                        return
//                    }
                    
//                    print( "running, \(offset), \(oldPhase), \(newPhase)" )
                    
                    if abs(velocity) < 40 && (newPhase == .idle || newPhase == .decelerating) {
                    
                    
                        if offset > -50 && offset < scrollThreshold {
                            scrollToContent()
                            
                        } else if offset < -60 {
                            scrollToHeader()
                        }
//                        
////                        withAnimation(.spring(duration: 0.1)) {
////                            makeScrollSnapping(in: geo, proxy: proxy)
////                        }
                    }
                }
            }
        }
    }
}


@available(iOS 18.0, *)
struct TestScroller: View, Animatable {
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                self.offset = value.translation.height
                self.scrollPosition.scrollTo(y: -offset)
                
            }
            .onEnded { value in
                self.offset = finalOffset
                withAnimation {
                    self.scrollPosition.scrollTo(y: 340)
                }
            }
    }
    
    @State private var inFullScreen: Bool = false
    
    @State private var offset: Double = 0
    
    @State private var scrollPosition: ScrollPosition = .init()
    
    @State private var flickingDownward: Bool = false
    
    @State private var scrollPhase: ScrollPhase = .idle
    
    private struct AnimatableTest: View {
        @Binding var offset: Double
        
        var body: some View {
            
            Text("\(offset)")
        }
        
    }
    
    
    private let finalOffset: Double = 340
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack(alignment: .top) {
                
                Rectangle()
                    .foregroundStyle(.blue)
                
                
                VStack {
                    Rectangle()
                        .foregroundStyle(.green)
                        .frame(height: max(500 - offset, 0))
                    
                    ScrollView(.vertical) {
                        
                        VStack {
                            
                            //                        if offset <= 200 - 62 {
                            //                        }
//                            
                            Rectangle()
                                .foregroundStyle(.red)
                                .frame(height: 500)
                            
                            
                            
                            ForEach(0..<20, id: \.self) { i in
                                Rectangle()
                                    .foregroundStyle(.purple)
                                    .frame(height: 100)
                                    .overlay {
                                        Text("\(i)")
                                    }
                                    .offset(y: -500 + min(500, offset))
                            }
                        }
                    }
                    .frame(height: geo.size.height)
                    .scrollPosition($scrollPosition)
                    
                    //                .offset(y: )
                    
                    .onScrollGeometryChange(for: CGPoint.self, of: { geo in geo.contentOffset }, action: { oldValue, newValue in
                        self.offset = newValue.y
                        
                        if newValue.y - oldValue.y < -30 && offset > 0 && scrollPhase != .interacting {
                            print("scroll down")
                            withAnimation(.easeOut(duration: 5)) {
    //                            self.offset = 0
                                scrollPosition.scrollTo(y: 0)
                                
                                self.flickingDownward = true
                            }
                        }
                        
                        if offset > 490 {
                            self.inFullScreen = true
                        } else {
                            self.inFullScreen = false
                        }
                        
                        if offset == 0 {
                            self.flickingDownward = false
                        }
                    })
                    .onScrollPhaseChange { oldPhase, newPhase in
                        
                        self.scrollPhase = newPhase
                        
                        if (newPhase == .decelerating || newPhase == .idle) && offset > 30 && !inFullScreen && !flickingDownward {
                            print("scroll up!")
//                            withAnimation {
                                scrollPosition.scrollTo(y: 500)
                            withAnimation(.easeOut(duration: 0.5)) {
                                self.offset = 500
                            }
//                            }
                        }
                    }
                    //                .defaultScrollAnchor(.init(x: 0.5, y: 0.5), for: .initialOffset)
                    .border(.red)
//                    .animation( .easeOut(duration: 0.2), value: offset )
//                    .animation( .easeOut(duration: 0.5), value: scrollPosition )
                    
                }
                
                RecallIcon("text.document.fill")
                    .background()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 5)) {
//                            self.offset = 0
                            scrollPosition.scrollTo(y: 0)
                            
//                            self.flickingDownward = true
                        }
                    }
            }
        }
        .overlay(content: {
            AnimatableTest(offset: $offset)
        })
    }
}

@available(iOS 18.0, *)
#Preview {
    TestScroller()
//    PhotoScrollerView {
//        VStack {
//            
//            Text("hi there!")
//                .bold()
//                .font(.title)
//            
//            Spacer()
//        }
//        
//    } bodyContent: {
//        LazyVStack {
//            ForEach( 0...50, id: \.self ) { i in
//                
//                Rectangle()
//                    .frame(height: 50)
//                    .foregroundStyle(.red)
//                    .opacity(Double(i) / 50)
//            }
//        }
//        
//    }
}
