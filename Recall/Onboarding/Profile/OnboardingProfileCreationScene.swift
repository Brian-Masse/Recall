//
//  OnboardingprofileCreationSCene.swift
//  Recall
//
//  Created by Brian Masse on 1/2/25.
//

import Foundation
import SwiftUI
import UIUniversals
import RealmSwift

//MARK: - OnboardingProfleCreationScene
struct OnboardingProfileCreationScene: View {

    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var birthday: Date = .now
    
    private var formsComplete: Bool {
        !(firstName.isEmpty || lastName.isEmpty || -(birthday.timeIntervalSinceNow) < Constants.yearTime * 18 || email.isEmpty)
    }
    
    private func loadProfileInfo() {
        self.firstName = RecallModel.index.firstName
        self.lastName = RecallModel.index.lastName
        self.email = RecallModel.index.email
        self.birthday = RecallModel.index.dateOfBirth
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
        
        if RecallModel.index.email.isEmpty {
            StyledTextField(title: "",
                            binding: $email,
                            prompt: "email")
        }
        
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
            .onAppear { loadProfileInfo() }
            .onChange(of: firstName) {
                viewModel.setSceneStatus(to: formsComplete ? .complete : .incomplete)
            }
            .onChange(of: lastName) {
                viewModel.setSceneStatus(to: formsComplete ? .complete : .incomplete)
            }
            .onChange(of: email) {
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
                                                        email: email,
                                                        birthday: birthday)
                })
            }
        }
    }
}





//MARK: - OnboardingProfileSettingsScene
struct OnboardingProfileSettingsScene: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedRealmObject var index = RecallModel.index
    
    @ObservedObject private var viewModel = OnboardingViewModel.shared
    
//    MARK: makeHeader
    @ViewBuilder
    private func makeHeader() -> some View {
        HStack {
            VStack(alignment: .leading) {
                UniversalText( "Customize Recall", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                
                UniversalText( "You can change all of these settings later in your profile", size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                    .opacity(0.75)
            }
            
            Spacer()
        }
    }
    
//    MARK: - CalendarDensity
    @ViewBuilder
    private func makeCalendarDensitySelector(_ option: Int, caption: String) -> some View {
        VStack {
            let colorScheme = colorScheme == .dark ? "dark" : "light"
            
            Image("\(colorScheme)-calendar-desnity-\(option)")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipped()
                .padding(.bottom, 5)
            
            UniversalText(caption, size: Constants.UISmallTextSize, font: Constants.titleFont)
                .if( index.calendarDensity == option ) { view in view.foregroundStyle(.black) }
        }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: Constants.UIDefaultCornerRadius)
                    .universalStyledBackgrond(.accent, onForeground: true)
                    .opacity(index.calendarDensity == option ? 1 : 0)
            }
            .onTapGesture { withAnimation {
                index.setCalendarDensity(to: option)
            } }
    }
    
    @ViewBuilder
    private func makeCalendarDensitySection() -> some View {
        VStack(alignment: .leading) {
            makeSectionHeader("calendar.day.timeline.left", title: "Calendar")
            
            VStack {
                HStack(spacing: 0) {
                    makeCalendarDensitySelector(0, caption: "compact")
                    makeCalendarDensitySelector(1, caption: "regular")
                    makeCalendarDensitySelector(2, caption: "roomy")
                }.padding(.bottom)
                
                makeCalendarColoumnCountSection()
            }
            .rectangularBackground(style: .secondary, stroke: true)
        }
    }
    
//    MARK: CalendarColoums
    @ViewBuilder
    private func makeCalendarColoumnCountOption(_ option: Int, icon: String) -> some View {
        UniversalButton {
            HStack {
                Spacer()
                RecallIcon( icon )
                Spacer()
            }
            .highlightedBackground(index.calendarColoumnCount == option, disabledStyle: .primary)
            
        } action: { index.setCalendarColoumnCount(to: option) }
    }
    
    @ViewBuilder
    private func makeCalendarColoumnCountSection() -> some View {
        HStack(spacing: 10) {
            makeCalendarColoumnCountOption(1, icon: "rectangle")
            makeCalendarColoumnCountOption(2, icon: "rectangle.split.2x1")
            makeCalendarColoumnCountOption(3, icon: "rectangle.split.3x1")
        }
    }
    
//    MARK: AppColor
    @ViewBuilder
    private func makeAccentColorOption(_ accentColor: Colors.AccentColor, index: Int) -> some View {
        VStack {
            ZStack {
                Circle()
                    .foregroundStyle(accentColor.lightAccent)
                
                Circle()
                    .foregroundStyle(accentColor.darkAccent)
                    .clipShape(Triangle())
            }
            .padding(10)
            .background(
                Circle().foregroundStyle(self.index.recallAccentColorIndex == index ? Colors.getBase(from: colorScheme) : .clear)
            )
            
            UniversalText( accentColor.title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        }
        .onTapGesture {
            viewModel.triggerBackgroundUpdate.toggle()
            withAnimation { self.index.setAccentColor(to: index) }
        }
    }
    
//    MARK: makeAccentColorPicker
    @ViewBuilder
    private func makeAccentColorSection() -> some View {
        VStack(alignment: .leading) {
            makeSectionHeader("circle.circle", title: "Accent Color")
            
            GeometryReader { geo in
                let coloumnCount: Double = 4
                let spacing: Double = 10
                let width = (geo.size.width - (spacing * (coloumnCount + 1))) / coloumnCount
                
                LazyVGrid(columns: [ .init(.adaptive(minimum: width, maximum: width),
                                           spacing: spacing,
                                           alignment: .center) ]) {
                    ForEach( 0..<Colors.accentColorOptions.count, id: \.self ) { i in
                        let color = Colors.accentColorOptions[i]
                        makeAccentColorOption(color, index: i)
                    }
                }
            }
            .frame(height: 225)
            .rectangularBackground(style: .secondary, stroke: true)
        }
    }
    
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            makeHeader()
                .padding(.bottom)
            
                makeAccentColorSection()
                    .padding(.bottom)
                
                makeCalendarDensitySection()
                    .padding(.bottom)
            
            Spacer()
        }
        .padding(7)
        .overlay(alignment: .bottom) {
            OnboardingContinueButton()
        }
        .onAppear() { viewModel.setSceneStatus(to: .complete)}
    }
}

#Preview {
    OnboardingProfileSettingsScene()
}
