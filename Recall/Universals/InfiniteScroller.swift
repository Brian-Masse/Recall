//
//  TestInfiniteScroller.swift
//  Recall
//
//  Created by Brian Masse on 10/7/24.
//

import Foundation
import SwiftUI


//MARK: InfiniteScroller
struct InfiniteScroller<Content: View>: View {
    
    let contentBuilder: (Int) -> Content
    
    init( @ViewBuilder contentBuilder: @escaping (Int) -> Content ) {
        self.contentBuilder = contentBuilder
    }
    
    @State private var upperBound: Int = -1
    @State private var lowerBound: Int = 10
    
    @State private var offset: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    
                    ForEach( upperBound...lowerBound, id: \.self ) { i in
                        contentBuilder(i)
                            .overlay { if i == -1 {
                                GeometryReader { geo in
                                    Rectangle()
                                        .foregroundStyle(.clear)
                                        .onAppear() { self.offset = geo.size.height }
                                }}
                                
                            }
                            .onAppear {
                                if offset != 0 || i == -1 {
                                    if i == upperBound { upperBound -= 1 }
                                    if i == lowerBound { lowerBound += 1 }
                                }
                            }
                    }
                }
                .offset(y: -offset * 0.5)
            }
        }
    }
}
