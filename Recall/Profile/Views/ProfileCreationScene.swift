//
//  ProfileCreationScene.swift
//  Recall
//
//  Created by Brian Masse on 9/7/23.
//

import Foundation
import RealmSwift
import SwiftUI
import UIUniversals

struct ProfileCreationView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
//    MARK: ProfileCreationScene
    private enum ProfileCreationScene: Int, CaseIterable, Identifiable {
        
        case splash
        case name
        case phoneNumber
        case birthday
        case reminders
        case complete
        
        var id: Int { self.rawValue }
        
        func advanceScene() -> ProfileCreationScene {
            ProfileCreationScene(rawValue:  self.rawValue + 1 ) ?? .splash
        }
        
        func returnScene() -> ProfileCreationScene {
            ProfileCreationScene(rawValue: max( self.rawValue - 1, 0 )) ?? .splash
        }
        
        func getName() -> String {
            switch self {
            case .reminders:    return "preferences"
            case .complete:     return "complete"
            case .splash:       return "introduction"
            default:            return "demographics"
            }
        }
    }
    
//    MARK: vars
    
    @State var showingError: Bool = false
    
    @State private var activeScene: ProfileCreationScene = .splash
    
    @State var firstName: String    = ""
    @State var lastName: String     = ""
    @State var email: String        = RecallModel.index.email
    @State var phoneNumber: Int     = 1
    @State var dateOfBirth: Date    = .now
    
    @State var enabledReminder: Bool = false
    @State var reminderTime:    Date = .now
    
    @State var showingContinueButton: Bool = false
    
//    MARK: Conveineience Functions
    private func validatePhoneNumber( _ number: Int ) -> Bool {
        "\(number)".count >= 10
    }
    
    private func validateBirthday(_ date: Date) -> Bool {
        Date.now.getYearsSince(date) >= 18
    }
    
    private func progressScene() {
        withAnimation {
            activeScene = activeScene.advanceScene()
            
            showingContinueButton = false
        }
    }
    
    @MainActor
    private func submit(skipTutorial: Bool) {
        
        withAnimation {
            RecallModel.index.update(firstName: firstName,
                                     lastName: lastName,
                                     email: email,
                                     phoneNumber: phoneNumber,
                                     dateOfBirth: dateOfBirth)
            
            RecallModel.index.postProfileCreationInit()
            
            if skipTutorial {
                RecallModel.index.completeOnboarding()
                RecallModel.realmManager.setState(.complete)
            }
//            if !skipTutorial { RecallModel.realmManager.setState(.tutorial) }
        }
    }
    
    
//    MARK: ViewBuilders
    
    
    
    @MainActor
    @ViewBuilder
    private func makeHeader() -> some View {
        
        ZStack {
            HStack {
                RecallIcon("arrow.backward")
                UniversalText( "back", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                Spacer()
            }
//            .onTapGesture { withAnimation {
//                if activeScene.rawValue == 0 {
//                    RecallModel.realmManager.logoutUser()
//                    RecallModel.realmManager.setState(.splashScreen)
//                }
//                activeScene = activeScene.returnScene()
//            } }
            
            HStack {
                Spacer()
                VStack {
                    UniversalText( activeScene.getName(), size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                    makeProgressBar()
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func makeNextButton() -> some View {
        
        ConditionalLargeRoundedButton(title: "continue", icon: "arrow.forward") { showingContinueButton } action: {
            progressScene()
        }
    }
    
//    MARK: Progress Bar
    @ViewBuilder
    private func makeProgressBar() -> some View {
        
        ZStack(alignment: .leading) {
            Rectangle()
                .cornerRadius(Constants.UIDefaultCornerRadius)
                .universalTextStyle()
                .opacity(0.2)
                .frame(width: 50, height: 10)
            
            let progress = Double( activeScene.rawValue ) / Double( ProfileCreationScene.allCases.count - 1 )
            
            Rectangle()
                .cornerRadius(Constants.UIDefaultCornerRadius)
                .universalStyledBackgrond(.accent, onForeground: true)
                .frame(width: 50 * progress, height: 10)
            
        }
        
    }

    @ViewBuilder
    private func makeSplashScreen() -> some View {
        VStack {
            Spacer()
            UniversalText("Get started by creating your Recall profile", size: Constants.UITitleTextSize, font: Constants.titleFont)
                .padding(.trailing, 50)
                .universalTextStyle()
                .onAppear { showingContinueButton = true }
            Spacer()
        }
        .slideTransition()
    }
    
//    MARK: Name
    @ViewBuilder
    private func makeNameScene() -> some View {
        VStack {
            StyledTextField(title: "What is your first name?", binding: $firstName)
                .padding(.bottom)
            
            StyledTextField(title: "What is your last name?", binding: $lastName)
                .padding(.bottom)
        }
        .slideTransition()
        .onAppear() {
            if RealmManager.usedSignInWithApple { progressScene() }
            showingContinueButton = ( !firstName.isEmpty && !lastName.isEmpty )
        }
        .onChange(of: firstName)    {
            showingContinueButton = ( !firstName.isEmpty && !lastName.isEmpty )
        }
        .onChange(of: lastName)     {
            showingContinueButton = ( !firstName.isEmpty && !lastName.isEmpty )
        }
    }
    
//    MARK: PhoneNumber
    @ViewBuilder
    private func makePhoneNumberScene() -> some View {
        
        let phoneBinding: Binding<String> = {
           
            Binding {
                phoneNumber.formatIntoPhoneNumber()
            } set: { (newValue, _) in
                phoneNumber = Int( newValue.removeNonNumbers() ) ?? phoneNumber
            }
        }()
        
        VStack {
            
            StyledTextField(title: "What is your email?", binding: $email)
                .padding(.bottom)
            
            StyledTextField( title: "What is your phone number?", binding: phoneBinding )
                .keyboardType(.numberPad)
            
            
        }
        .slideTransition()
        .onAppear() {
            showingContinueButton = ( !email.isEmpty && validatePhoneNumber(phoneNumber) )
        }
        .onChange(of: email) {
            showingContinueButton = ( !email.isEmpty && validatePhoneNumber(phoneNumber) )
        }
        .onChange(of: phoneNumber) {
            showingContinueButton = ( !email.isEmpty && validatePhoneNumber(phoneNumber) )
        }
        
    }
    
//    MARK: Birthday
    @ViewBuilder
    private func makeDateOfBirthSelector() -> some View {
        
        VStack(alignment: .leading) {
            
            StyledDatePicker($dateOfBirth, title: "When is your birthday?")
            
//            if !validateBirthday(dateOfBirth) {
                UniversalText( "tap and hold on the date to change", size: Constants.UISmallTextSize, font: Constants.mainFont )
                    .padding(.leading)
//            }
        }
        .slideTransition()
        .onAppear() { showingContinueButton = validateBirthday( dateOfBirth ) }
        .onChange(of: dateOfBirth) {
            showingContinueButton = validateBirthday(dateOfBirth)
        }
    }
    
//    MARK: Notifications
    @ViewBuilder
    private func makeNotificationSelector(label: String) -> some View {
        HStack {
            Spacer()
            UniversalText( label, size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            RecallIcon("arrow.up.forward")
            Spacer()
        }
    }
    
    @ViewBuilder
    private func makeNotificationsScene() -> some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( "Would you like to be reminded of your daily Recalls?", size: Constants.UIHeaderTextSize, font: Constants.titleFont )

            HStack {
                makeNotificationSelector(label: "yes")
                    .rectangularBackground(style: .accent, foregroundColor: .black)
                    .onTapGesture { withAnimation {
                        showingContinueButton = true
                        Task {
                            let results = await NotificationManager.shared.requestNotifcationPermissions()
                            if results { enabledReminder = true }
                            else { progressScene() }
                        }
                    }}
                
                makeNotificationSelector(label: "no, thanks")
                    .rectangularBackground(style: .secondary)
                    .onTapGesture { withAnimation {
                        showingContinueButton = true
                        enabledReminder = false
                        progressScene()
                    }}
            }
            
            if !enabledReminder {
                UniversalText( "you can change reminder preferences in settings.", size: Constants.UISmallTextSize, font: Constants.mainFont )
                    .padding(.leading)
            } else {
                
                TimeSelector(label: "What time would you like to receieve your reminder", time: $reminderTime)
                    .padding(.top)
            }
        }
        .onAppear() { showingContinueButton = true }
        .slideTransition()
    }
    
//    MARK: completion
    
    @ViewBuilder
    private func makeCompletionScreenNode(title: String, icon: String, color: Color, size: Double, verticalSpace: CGFloat, hideMetaData: Bool = false, startTime: Date = .now, endTime: Date = .now, tag: String = "", function: @escaping () -> Void ) -> some View {
       
        VStack {
            HStack {
                UniversalText( title, size: size, font: Constants.titleFont )
                Spacer()
                RecallIcon(icon)
            }
            
            if !hideMetaData {
                Rectangle()
                    .frame(height: verticalSpace)
                    .foregroundColor(.clear)
                
                HStack {
                    
                    RecallIcon("tag")
                    UniversalText( tag, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                    
                    Spacer()
                    
                    let timeString = "\( startTime.formatted( date: .omitted, time: .shortened ) ) - \( endTime.formatted( date: .omitted, time: .shortened ) )"
                    UniversalText( timeString, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                }
            }
        }
        .foregroundColor(.black)
        .padding()
        .padding(.vertical, 5)
        .background(
            Rectangle()
                .foregroundColor(color)
                .cornerRadius(Constants.UILargeCornerRadius)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 7)
        )
        .onTapGesture { function() }
        
        
    }
    
    @MainActor
    @ViewBuilder
    private func makeCompletionScreen() -> some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .onTapGesture { submit(skipTutorial: false) }
            
            VStack {
                
                Spacer()
                
                makeCompletionScreenNode(title: "Your profile is all set up",
                                         icon: "checkmark",
                                         color: Colors.red,
                                         size: Constants.UITitleTextSize,
                                         verticalSpace: 30,
                                         startTime: .now,
                                         endTime: .now + Constants.HourTime * 2,
                                         tag: "success") { submit(skipTutorial: false) }
                    .rotationEffect(.init(degrees: 1))
                
                makeCompletionScreenNode(title: "Get started by recalling your day",
                                         icon: "arrow.up.forward",
                                         color: Colors.yellow,
                                         size: Constants.UIHeaderTextSize,
                                         verticalSpace: 20,
                                         startTime: .now + Constants.HourTime * 2.5,
                                         endTime: .now + Constants.HourTime * 3.75,
                                         tag: "onwards and upwards") { submit(skipTutorial: false) }
                                         .rotationEffect(.init(degrees: -1))
                                         .offset(y: -12)
                                         .zIndex(10)
                
                Spacer()
                
                makeCompletionScreenNode(title: "or jump straight into the app",
                                         icon: "arrow.forward",
                                         color: Colors.getAccent(from: colorScheme),
                                         size: Constants.UIDefaultTextSize,
                                         verticalSpace: 10,
                                         hideMetaData: true) { showingError = true }
            }
        }
        .slideTransition()
        .alert("Continue to app?",
               isPresented: $showingError,
               actions: {
            Button("continue", role: .destructive) { submit(skipTutorial: true) }
            Button("cancel", role: .cancel) { showingError = false }
        }, message: {
            Text( "Proceeding will skip the tutorial." )
        })
    }
    
    
    
//    MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            makeHeader()
                .padding(.bottom, 20)
            
            VStack {
                switch activeScene {
                case .splash:       makeSplashScreen()
                case .name:         makeNameScene()
                case .phoneNumber:  makePhoneNumberScene()
                case .birthday:     makeDateOfBirthSelector()
                case .reminders:    makeNotificationsScene()
                case .complete:     makeCompletionScreen()
                }
            }
            
            if activeScene != .complete {
                Spacer()
                
                makeNextButton()
            }
        }
        .onTapGesture {
            self.hideKeyboard()
        }
        .padding(.bottom, 30)
        .padding(7)
        .universalBackground()
    }
}
