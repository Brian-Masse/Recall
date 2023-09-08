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
    
    @State var loggingIn: Bool = false
    
    private func formsFilledIn() -> Bool {
        !email.isEmpty && !password.isEmpty
    }
    
//    MARK: Methods
    private func submit() async {
        
        loggingIn = true
        
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
                UniversalText("Create a Recall account", size: Constants.UITitleTextSize, font: Constants.titleFont)
                    .padding(.bottom)

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
                    
                    
                    ZStack {
                        ConditionalLargeRoundedButton(title: "create / login",
                                                      icon: "arrow.forward",
                                                      condition: checkCompletion) { Task { await submit() }  }
                        
                        if loggingIn { ProgressView() }
                    }.onAppear() { loggingIn = false }
                    
                }
                .universalTextStyle()
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 30)
        .padding(7)
        .ignoresSafeArea()
        .universalBackground()
        .defaultAlert($showingError, title: "Issue Signing in", description: self.message)
        .transition(.push(from: .trailing))
//        .preferredColorScheme(.light)
    }
}
