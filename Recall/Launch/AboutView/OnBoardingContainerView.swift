//
//  OnBoardingContainerView.swift
//  Recall
//
//  Created by Brian Masse on 12/24/24.
//

import Foundation
import SwiftUI
import UIUniversals

//MARK: - OnBoardingScene
enum OnBoardingScene: Int, CaseIterable {
    case overview
    case howItWorks
    
    func incrementScene() -> OnBoardingScene {
        if let scene = OnBoardingScene(rawValue: self.rawValue + 1) { return scene }
        else { return self }
    }
    
    func decrementScene() -> OnBoardingScene {
        if let scene = OnBoardingScene(rawValue: self.rawValue - 1) { return scene }
        else { return self }
    }
}

//MARK: - OnBoardingContainerView
struct OnBoardingContainerView<C: View>: View {
    
    @State private var scene: OnBoardingScene = .overview
    
    @ViewBuilder
    private var sceneBuilder: ((OnBoardingScene) -> C)
    
//    MARK: Init
    init( @ViewBuilder contentBuilder: @escaping (OnBoardingScene) -> C ) {
        self.sceneBuilder = contentBuilder
    }
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                sceneBuilder(scene)
                    .frame(width: geo.size.width, height: geo.size.height)
                
                IconButton("arrow.forward",
                           label: "Continue",
                           fullWidth: true) { withAnimation {
                    self.scene = scene.incrementScene()
                } }
            }
        }
    }
}

#Preview {
    OnBoardingContainerView { scene in
        switch scene {
        case .overview: Text("overview")
        case .howItWorks: Text("how it works")
        }
    }
}
