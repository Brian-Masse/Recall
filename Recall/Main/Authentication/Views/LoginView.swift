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
    
    var body: some View {
        
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
        .signInWithAppleButtonStyle(.black)
        
        
    }
    
}
