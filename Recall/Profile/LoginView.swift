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
import UIUniversals

//This displays after the splash screen and prompts users to sign in / login
struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State var email: String = ""
    @State var password: String = ""
    
    @State var showingAlert: Bool = false
    @State var alertTitle: String = "Issue Signing In"
    @State var alertMessage: String = ""
    
    @State var loggingIn: Bool = false
    
    private func formsFilledIn() -> Bool {
        !email.isEmpty && !password.isEmpty
    }
    
//    MARK: Methods
    private func submit() async {
        loggingIn = true
        
        if checkCompletion() {
            if let error = await RecallModel.realmManager.signInWithPassword(email: email, password: password) {
                alertMessage = error
                showingAlert = true
                loggingIn = false
            }
            
        } else {
            alertMessage = "please provide a valid email and password before continuing"
            showingAlert = true
            loggingIn = false
        }
    }
    
    private func checkCompletion() -> Bool {
        !email.isEmpty && !password.isEmpty
    }
    
//    MARK: ViewBuilders
    @ViewBuilder
    private func makeEmailPasswordAuthSection() -> some View {
        UniversalText( "Email + password", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
        
        TextField("email", text: $email)
            .rectangularBackground(style: .secondary)
            .universalTextField()
        SecureField("password", text: $password)
            .rectangularBackground(style: .secondary)
            .universalTextField()
            .padding(.bottom)
    }
    @MainActor
    @ViewBuilder
    private func makeSignInWithAppleSection() -> some View {
        if !RealmManager.offline {
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
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
            .cornerRadius(Constants.UIDefaultCornerRadius)
            .frame(height: 50)
        }
    }
    
    
//    MARK: Body
    var body: some View {

        VStack(alignment: .leading) {
            UniversalText("Create a Recall account", size: Constants.UITitleTextSize, font: Constants.titleFont)
                .padding(.bottom)

            makeEmailPasswordAuthSection()
            
            makeSignInWithAppleSection()
            
            Spacer()
                
            ConditionalLargeRoundedButton(title: "create / login",
                                              icon: "arrow.forward",
                                              condition: checkCompletion) { Task { await submit() }  }
            .onAppear() { loggingIn = false }
        }
        .universalTextStyle()
        .padding(.bottom, 40)
        .padding(7)
        .universalBackground()
        
        .transition(.push(from: .trailing))
        
        .alert(alertTitle, isPresented: $showingAlert) {
            Button( "dismiss", role: .cancel ) {}
        } message: {
            Text( alertMessage )
        }

    }
}
