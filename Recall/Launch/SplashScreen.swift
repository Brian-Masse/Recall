//
//  SplashScreen.swift
//  Recall
//
//  Created by Brian Masse on 8/21/23.
//

import Foundation
import RealmSwift
import SwiftUI
import UIUniversals

//This presents when the app launches for the first time, or when a user logs out
struct SplashScreen: View {
    @ObservedObject var realmManager = RecallModel.realmManager
    
//    MARK: Body
    var body: some View {
        
        GeometryReader { geo in
            VStack() {
                Spacer()
                
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing) {
                            UniversalText( "Recall", size: Constants.UILargeTextSize, font: Constants.titleFont )
                            UniversalText( "The best non-calendar, calendar tool.", size: Constants.UISubHeaderTextSize, font: Constants.mainFont, textAlignment: .trailing )
                        }
                        .universalTextStyle()
                        
                    }
                    Spacer()
                    
                    HStack {
                        LargeRoundedButton("Create an account or login", icon: "arrow.forward") {
//                            realmManager.setState(.authenticating)
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
        .transition(.asymmetric(insertion: .push(from: .leading), removal: .push(from: .trailing)))
    }
}
