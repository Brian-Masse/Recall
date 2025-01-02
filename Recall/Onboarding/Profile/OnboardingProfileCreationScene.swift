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
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        UniversalText( "Setup your Profile",
                       size: Constants.UISubHeaderTextSize,
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
        VStack(alignment: .leading) {
            makeHeader()
            
            makeDemographicsField()
            
            Spacer()
        }
        .padding(7)
        
    }
}

#Preview {
    OnboardingProfileCreationScene()
}
