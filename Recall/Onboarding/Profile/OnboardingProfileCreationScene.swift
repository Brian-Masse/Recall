//
//  OnboardingprofileCreationSCene.swift
//  Recall
//
//  Created by Brian Masse on 1/2/25.
//

import Foundation
import SwiftUI
import UIUniversals


//MARK: OnboardingProfleCreationScene
struct OnboardingProfileCreationScene: View {

    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthday: Date = .now
    
    private var formsComplete: Bool {
        !(firstName.isEmpty || lastName.isEmpty || -(birthday.timeIntervalSinceNow) < Constants.yearTime * 18)
    }
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        UniversalText( "Setup your Profile",
                       size: Constants.UIHeaderTextSize,
                       font: Constants.titleFont )
    }
    
//    MARK: makeDemographicsField
    @ViewBuilder
    private func makeDemographicsField() -> some View {
        StyledTextField(title: "",
                        binding: $firstName,
                        prompt: "First Name")
        
        StyledTextField(title: "",
                        binding: $lastName,
                        prompt: "Last Name")
        
        StyledDatePicker($birthday, title: "", prompt: "birthday")
    }
    
//    MARK: Body
    var body: some View {
        OnboardingSplashScreenView(icon: "person.bust",
                                   title: "Profile",
                                   message: OnboardingSceneUIText.profileSceneIntroductionText) {
            VStack(alignment: .leading) {
                makeHeader()
                
                makeDemographicsField()
                
                Spacer()
            }
            .onChange(of: firstName) {
                viewModel.setSceneStatus(to: formsComplete ? .complete : .incomplete)
            }
            .onChange(of: lastName) {
                viewModel.setSceneStatus(to: formsComplete ? .complete : .incomplete)
            }
            .onChange(of: birthday) {
                viewModel.setSceneStatus(to: formsComplete ? .complete : .incomplete)
            }
            
            .padding(7)
            .overlay(alignment: .bottom) {
                OnboardingContinueButton(preTask: {
                    viewModel.submitProfileDemographics(firstName: firstName,
                                                        lastName: lastName,
                                                        birthday: birthday)
                })
            }
        }
    }
}

#Preview {
    OnboardingProfileCreationScene()
}
