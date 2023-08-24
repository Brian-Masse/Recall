//
//  LoginView.swift
//  Recall
//
//  Created by Brian Masse on 8/21/23.
//

import Foundation
import SwiftUI
import RealmSwift
import AuthenticationServices

//BundleID: Masse-Brian.Recall
//KeyID: 22NTNRT72G

struct LoginView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var email: String = ""
    @State var password: String = ""
    
    @State var showingError: Bool = false
    @State var message: String = ""
    
    private func formsFilledIn() -> Bool {
        !email.isEmpty && !password.isEmpty
    }
    
//    MARK: Methods
    private func submit() async {
        if checkCompletion() {
            if let error = await RecallModel.realmManager.signInWithPassword(email: email, password: password) {
                message = error
                showingError = true
            }
            
        } else {
            message = "please provide a valid email and password before continuing"
            showingError = true
        }
    }
    
    private func checkCompletion() -> Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack {
            
            VStack(alignment: .leading) {
                UniversalText("Create an account with Recall", size: Constants.UITitleTextSize, font: Constants.titleFont)
                    .padding(.bottom, 5)
                    .foregroundColor(.black)

                ZStack(alignment: .bottom) {
                    ScrollView(.vertical) {
                        VStack(alignment: .leading) {
                            
//                            MARK: Email Password
                            UniversalText( "Email + password", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                            
                            TextField("email", text: $email)
                                .secondaryOpaqueRectangularBackground()
                                .universalTextField()
                            SecureField("password", text: $password)
                                .secondaryOpaqueRectangularBackground()
                                .universalTextField()
                                .padding(.bottom)
                            
//                           MARK: Sign in with Apple
                            UniversalText( "or sign in with Apple", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                                .padding(.vertical, 5)
                            
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                switch result {
                                case .success(let authResults):
                                    print("Authorisation with Apple successful")
                                    RecallModel.realmManager.signInWithApple(authResults)
                                    
                                case .failure(let error):
                                    print("Authorisation failed: \(error.localizedDescription)")
                                }
                            }
                            .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                            .cornerRadius(Constants.UIDefaultCornerRadius)
                            
                            Spacer()
                        }
                        .padding(.bottom, Constants.UIBottomOfPagePadding)
                    }
                    
                    
                    HStack {
                        Spacer()
                        UniversalText("create / login", size: Constants.UISubHeaderTextSize, font: Constants.titleFont)
                        Image(systemName: "arrow.forward")
                        Spacer()
                        
                    }
                        .padding(10)
                        .if( checkCompletion() ) { view in view.tintRectangularBackground() }
                        .if( !checkCompletion() ) { view in view.secondaryOpaqueRectangularBackground() }
                    
//                    LargeRoundedButton("create / login", icon: "arrow.forward", wide: true) { Task { await submit() } }
//                    .padding(.bottom)?
                    
                }
                .universalTextStyle()
                .opaqueRectangularBackground()
            }
        }
        .padding(.top, 50)
        .padding(.bottom, 30)
        .padding(7)
        .ignoresSafeArea()
        .universalBackgroundColor(ignoreSafeAreas: .all)
        .defaultAlert($showingError, title: "Issue Signing in", description: self.message)
        .transition(.asymmetric(insertion: .push(from: .trailing), removal: .push(from: .trailing)))
    }
}