//
//  SplashScreen.swift
//  Recall
//
//  Created by Brian Masse on 8/21/23.
//

import Foundation
import RealmSwift
import SwiftUI

struct SplashScreen: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var page: ContentView.EntryPage
    
    @ObservedObject var realmManager = RecallModel.realmManager
    
    var body: some View {
        
        GeometryReader { geo in
            VStack() {
                Spacer()
                
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing) {
                            UniversalText( "Recall", size: Constants.UILargeTextSize, font: Constants.titleFont )
                            UniversalText( "The best non-calendar calendar tool.", size: Constants.UISubHeaderTextSize, font: Constants.mainFont, textAlignment: .trailing )
                        }
                        .universalForegroundColor()
                        
                    }
                    Spacer()
                    
                    HStack {
                        LargeRoundedButton("Create an account or login", icon: "arrow.forward") {
                            withAnimation { page = .login }
                        }
                        Spacer()
                    }
                    .padding(.bottom, Constants.UIBottomOfPagePadding)
                }
                .frame(height: geo.size.height / 1.5)
            }
        }
        .ignoresSafeArea()
        .padding()
        .padding(.bottom)
        .universalBackground()
        .overlay(
            Image("PaperNoise")
                .resizable()
                .blendMode( colorScheme == .light ? .multiply : .lighten)
                .opacity( colorScheme == .light ? 0.65 : 0.25)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
        )
        .transition(.asymmetric(insertion: .push(from: .leading), removal: .push(from: .trailing)))
    }
}
