//
//  ProfileViewEditor.swift
//  Recall
//
//  Created by Brian Masse on 8/24/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

@MainActor
struct ProfileEditorView: View {
    
    private enum Incompletion: String {
        case age = "you must be 18 years or older to register"
        case incomplete = "please provide your name, email, phone number, and birthday to continue"
        case phoneNumber = "please provide a valid 10 digit phone number"
        case none = ""
    }
    
//    MARK: Methods
    private func submit() {
        
        let completion = checkCompletion()
        if completion != .none {
            errorMessage = completion.rawValue
            showingError = true
            return
        }
        
        index.update(firstName: firstName,
                     lastName: lastName,
                     email: email,
                     phoneNumber: phoneNumber,
                     dateOfBirth: dateOfBirth)
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func checkCompletion() -> Incompletion {
        if Date.now.getYearsSince(dateOfBirth) < 18 { return .age }
        if "\(phoneNumber)".count < 10 { return .phoneNumber }
        if email.isEmpty || firstName.isEmpty || lastName.isEmpty { return .incomplete }
        else { return .none  }
    }
    
    
//    MARK: Vars
    @Environment(\.presentationMode) var presentationMode
    let index = RecallModel.index
    
    @State var email: String
    @State var phoneNumber: Int
    @State var dateOfBirth: Date
    
    @State var firstName: String
    @State var lastName: String
    
    @State var errorMessage: String = ""
    @State var showingError: Bool = false
    
//    MARK: ViewBuilders
    
    private func makePhoneNumberBinding() -> Binding<String> {
        
        Binding {
            phoneNumber.formatIntoPhoneNumber()
        } set: { str, _ in
            let num = Int(str.removeNonNumbers()) ?? phoneNumber
            phoneNumber = num
        }

        
    }
    
    @ViewBuilder
    private func makeNameSection() -> some View {
        
        VStack(alignment: .leading) {
            UniversalText( "What's your first and last name?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            
            TextField("first name", text: $firstName)
                .universalTextField()
                .rectangularBackground(style: .secondary)
            
            TextField("last name", text: $lastName)
                .universalTextField()
                .rectangularBackground(style: .secondary)
        }
    }
    
    @ViewBuilder
    private func makeContactInformationSection() -> some View {
            
        VStack(alignment: .leading) {
            TextFieldWithPrompt(title: "email", binding: $email)
            
            UniversalText( "phone number", size: Constants.UIHeaderTextSize, font: Constants.titleFont  )
            TextField( "phoneNumber", text: makePhoneNumberBinding() )
                .universalTextField()
                .rectangularBackground(style: .secondary)
                .keyboardType(.numberPad)
        }
    }
    
    @ViewBuilder
    private func makeDateOfBirthSelector() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "Date of Birth", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            DatePicker(selection: $dateOfBirth, displayedComponents: .date) {
                UniversalText( "select", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            }
            .tint(Colors.tint)
            .rectangularBackground(style: .secondary)
        }
        
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
                
            UniversalText("Edit Profile", size: Constants.UITitleTextSize, font: Constants.titleFont)
                .foregroundColor(.black)
                .padding(.bottom, 5)
            
            ZStack (alignment: .bottom) {
                
                ScrollView(.vertical) {
                    VStack(alignment: .leading) {
                        
                        makeNameSection()
                            .padding(.bottom, 5)
                        
                        makeContactInformationSection()
                            .padding(.bottom, 5)
                        
                        makeDateOfBirthSelector()
                            .padding(.bottom, Constants.UIBottomOfPagePadding)
                        
                    }
                }
                .rectangularBackground(style: .primary)
                
                LargeRoundedButton("done", icon: "arrow.down") { submit() }
                    .padding(.bottom, 20)
            }
        }
        .scrollDismissesKeyboard(ScrollDismissesKeyboardMode.immediately)
        .padding([.top, .horizontal], Constants.UIFormPagePadding)
        .universalStyledBackgrond(.accent)
        .defaultAlert($showingError,
                      title: "Incomplete Form",
                      description: "\(errorMessage)")
    }
}
