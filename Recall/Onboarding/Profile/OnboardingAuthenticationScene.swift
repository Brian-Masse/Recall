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

//MARK: - OnboardingAuthenticationScene
//This displays after the splash screen and prompts users to sign in / login
struct OnboardingAuthenticationScene: View, OnboardingSceneView {
    @Environment(\.colorScheme) var colorScheme
    
    
//    MARK: Vars
    @State var email: String = ""
    @State var password: String = ""
    
    @State var showingAlert: Bool = false
    @State var alertTitle: String = "Issue Signing In"
    @State var alertMessage: String = ""
    
    @State var loggingIn: Bool = false
    
    var sceneComplete: Binding<Bool>
    
    private var formsComplete: Bool { !email.isEmpty && !password.isEmpty }
    
//    MARK: Submit
    private func submit() async {
        loggingIn = true
        
        if formsComplete {
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
    
//    MARK: - makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        UniversalText("Create a Recall account",
                      size: Constants.UIHeaderTextSize,
                      font: Constants.titleFont)
    }
    
//    MARK: makeEmailPasswordSection
    @ViewBuilder
    private func makeEmailPasswordAuthSection() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "Email + Password",
                           size: Constants.UIDefaultTextSize,
                           font: Constants.mainFont)
            .opacity(0.75)
            
            StyledTextField(title: "",
                            binding: $email,
                            prompt: "Email",
                            clearable: true)
            
            StyledTextField(title: "",
                            binding: $password,
                            prompt: "password",
                            type: .secure)
        }
    }
    
//    MARK: makeSignInWithAppleSection
    @ViewBuilder
    private func makeSignInWithAppleSection() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "Sign in with Apple",
                           size: Constants.UISubHeaderTextSize,
                           font: Constants.mainFont )
            .opacity(0.75)
            
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
    
    
//    MARK: - Body
    var body: some View {

        VStack(alignment: .leading) {
            makeHeader()
                .padding(.bottom)
            
            makeEmailPasswordAuthSection()
                .padding(.bottom)
            
            makeSignInWithAppleSection()
                .padding(.bottom)
            
            Spacer()
        }
        .padding(7)
        
        .onChange(of: password) {
            withAnimation { sceneComplete.wrappedValue = formsComplete }
        }
        .onChange(of: email) {
            withAnimation { sceneComplete.wrappedValue = formsComplete }
        }
        
        
        .alert(alertTitle, isPresented: $showingAlert) {
            Button( "dismiss", role: .cancel ) {}
        } message: {
            Text( alertMessage )
        }
    }
}

#Preview {
    OnboardingAuthenticationScene(sceneComplete: .constant(true))
}
