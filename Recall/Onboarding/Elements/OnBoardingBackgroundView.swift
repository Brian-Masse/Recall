//
//  OnBoardingBackgroundView.swift
//  Recall
//
//  Created by Brian Masse on 12/23/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: OnBoardingBackgroundView
struct OnBoardingBackgroundView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var t: Float = 0.0
    @State var timer: Timer?
    
    private func getColors() -> [Color] {
        var mixingColors: [Color] = Array(repeating: colorScheme == .light ? .white : .black, count: 9)
        
        for i in 0..<mixingColors.count {
            let mixAmount = Double.random(in: 0.25...0.75)
            let newColor = Colors.getAccent(from: colorScheme).safeMix(with: mixingColors[i], by: mixAmount)
            mixingColors[i] = newColor
        }
        
        return mixingColors
    }
    
    @State private var colors: [Color] = []
    
    @ViewBuilder
    private func makeGradient() -> some View {
        MeshGradient(width: 3, height: 3, points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),

            [sinInRange(-0.8...(-0.2), offset: 0.439, timeScale: 0.342, t: t), sinInRange(0.3...0.7, offset: 3.42, timeScale: 0.984, t: t)],
            
            [sinInRange(0.1...0.8, offset: 0.239, timeScale: 0.084, t: t), sinInRange(0.2...0.8, offset: 5.21, timeScale: 0.242, t: t)],
            
            [sinInRange(1.0...1.5, offset: 0.939, timeScale: 0.084, t: t), sinInRange(0.4...0.8, offset: 0.25, timeScale: 0.642, t: t)],
            
            [sinInRange(-0.8...0.0, offset: 1.439, timeScale: 0.442, t: t), sinInRange(1.4...1.9, offset: 3.42, timeScale: 0.984, t: t)],
            
            [sinInRange(0.3...0.6, offset: 0.339, timeScale: 0.784, t: t), sinInRange(1.0...1.2, offset: 1.22, timeScale: 0.772, t: t)],
            
            [sinInRange(1.0...1.5, offset: 0.939, timeScale: 0.056, t: t), sinInRange(1.3...1.7, offset: 0.47, timeScale: 0.342, t: t)]
        ], colors: colors)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                t += 0.02
            }
        }
        .background(.black)
        .ignoresSafeArea()
    }
    
    func sinInRange(_ range: ClosedRange<Float>, offset: Float, timeScale: Float, t: Float) -> Float {
        let amplitude = (range.upperBound - range.lowerBound) / 2
        let midPoint = (range.upperBound + range.lowerBound) / 2
        return midPoint + amplitude * sin(timeScale * t + offset)
    }
    
    let startDate: Date = .now
    
//    MARK: Body
    var body: some View {
        
        ZStack {
            makeGradient()
                .scaleEffect(1.3)
                .onAppear { self.colors = getColors() }
                .onChange(of: colorScheme) { self.colors = getColors() }
                .animation(.easeInOut, value: self.colors)
            
            TimelineView(.animation) { context in
                Rectangle()
//                    .colorEffect(ShaderLibrary.noise(.float(startDate.timeIntervalSinceNow.round(to: 2) )))
                    .blendMode(.softLight)
                    .opacity(0.5)
                    .ignoresSafeArea()
            }
        }
    }
}


#Preview {
    OnBoardingBackgroundView()
}