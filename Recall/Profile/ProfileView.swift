//
//  ProfileView.swift
//  Recall
//
//  Created by Brian Masse on 8/21/23.
//

import Foundation
import SwiftUI

@MainActor
struct ProfileView: View {
    
//    MARK: Vars
    
    @Namespace var profileNamespace
    
    @State var showingDataTransfer: Bool = false
    @State var showingEditingView: Bool = false
    @State var ownerID: String = ""
    
    @Binding var appPage: ContentView.EntryPage
    
    @State var madeChanges: Bool = false
    
    @State var notificationsEnabled: Bool = RecallModel.index.notificationsEnabled
    @State var notificationTime: Date = RecallModel.index.notificationsTime
    
    @State var activeIcon: String = ProfileView.initialComputeActiveIcon()
    
    private static func initialComputeActiveIcon() -> String {
        #if os(iOS)
        UIApplication.shared.alternateIconName ?? "light"
        #else
        "light"
        #endif
    }
    
    @State var showingError: Bool = false
    
    let index = RecallModel.index
    
//    MARK: Methods
    private func saveSettings() {
        index.toggleNotifcations(to: notificationsEnabled, time: notificationTime)
        madeChanges = false
    }
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeSubButton( title: String, icon: String, action: @escaping () -> Void ) -> some View {
        HStack {
            Spacer()
            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            Image(systemName: icon)
            Spacer()
        }
        .secondaryOpaqueRectangularBackground()
        .onTapGesture { action() }
    }
    
    @ViewBuilder
    private func makeContactLabel( title: String, content: String ) -> some View {
        HStack {
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            Spacer()
            UniversalText(content, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func makeDemographicLabel(mainText: String, secondaryText: String, tertiaryText: String) -> some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    UniversalText( mainText, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                    UniversalText( secondaryText, size: Constants.UIDefaultTextSize, font: Constants.mainFont, wrap: false, scale: true )
                }
                Spacer()
            }
            .secondaryOpaqueRectangularBackground()
            
            UniversalText( tertiaryText, size: Constants.UISmallTextSize, font: Constants.mainFont )
        }
    }
    
//    MARK: Overview
    @ViewBuilder
    private func makeDemographicInfo() -> some View {
        
        let dayFormatted: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd"
            return formatter
        }()
        
        let yearFormatted: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM, yyyy"
            return formatter
        }()
        
        
        UniversalText( "Overview", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
        VStack(alignment: .leading) {
            HStack {
                makeDemographicLabel(mainText: dayFormatted.string(from: index.dateJoined),
                                     secondaryText: yearFormatted.string(from: index.dateJoined),
                                     tertiaryText: "Date Joined")
                
                makeDemographicLabel(mainText: dayFormatted.string(from: index.dateOfBirth),
                                     secondaryText: yearFormatted.string(from: index.dateOfBirth),
                                     tertiaryText: "Date of Birth")
            }.padding(.bottom)
            
            UniversalText( "Contact Information", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                .padding(.bottom, 5 )
            makeContactLabel(title: "email", content: index.email)
            makeContactLabel(title: "phone number", content: "\(index.phoneNumber.formatIntoPhoneNumber())")
        }
        .opaqueRectangularBackground(7, stroke: true)
        .padding(.bottom, 5)
    }
    
//    MARK: settings
    @ViewBuilder
    private func makeReminderSettings() -> some View {
        UniversalText( "Reminders", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            .padding(.top, 5)
        
        HStack {
            UniversalText( "Daily reminder", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            Spacer()
            Toggle(isOn: $notificationsEnabled) { }
                .tint(Colors.tint)
                .onChange(of: notificationsEnabled) { newValue in
                    madeChanges = (newValue != index.notificationsEnabled)
                }
        }
        
        if notificationsEnabled {
            TimeSelector(label: "When would you like to be reminded?", time: $notificationTime, size: Constants.UIDefaultTextSize)
                .onChange(of: notificationTime) { newValue in
                    madeChanges = !( newValue.matches(index.notificationsTime, to: .minute) && newValue.matches(index.notificationsTime, to: .hour) )
                }
        }
        
        if madeChanges {
            ConditionalLargeRoundedButton(title: "save", icon: "arrow.forward") { madeChanges
            } action: { saveSettings() }
        }
    }
    
    @ViewBuilder
    private func makeIconPicker(icon: String) -> some View {
        let active = icon == activeIcon
        VStack {
            Image(icon)
                .resizable()
                .frame(width: 75, height: 75)
                .cornerRadius(15)
                .shadow(radius: 5)
            
            UniversalText( icon, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
                .if(active) { view in view.foregroundColor(.black) }
                .if(!active) { view in view.universalTextStyle() }
        }
        .padding(.horizontal, 25)
        .padding(5)
        .background( VStack {
            if active {
                Rectangle()
                    .universalForegroundColor()
                    .cornerRadius(Constants.UIDefaultCornerRadius)
                    .matchedGeometryEffect(id: "background", in: profileNamespace)
            }
            
        })
        #if os(iOS)
        .onTapGesture {
            withAnimation { activeIcon = icon }
            UIApplication.shared.setAlternateIconName(icon) { error in
                if let err = error { print( err.localizedDescription ) }
            }
        }
        #endif
    }
    
    @ViewBuilder
    private func makeIconSettings() -> some View {
        UniversalText( "Icon", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
        
        HStack {
            Spacer()
            makeIconPicker(icon: "light")
            Spacer()
            makeIconPicker(icon: "dark")
            Spacer()
        }
    }
    
    
    @ViewBuilder
    private func makeSettings() -> some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( "Settings", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            
            VStack(alignment: .leading) {
                makeReminderSettings()
                    .padding(.bottom)
                
                makeIconSettings()
                
            }
            .opaqueRectangularBackground(7, stroke: true)
            .padding(.bottom, 5)
            
            makeSubButton(title: "Replay Tutorial", icon: "arrow.clockwise") {
                index.replayTutorial()
                appPage = .login
            }
            
            makeSubButton(title: "reindex Data", icon: "tray.2") {
                Task { await RecallModel.index.initializeIndex() }
            }
            
            makeSubButton(title: "delete account", icon: "shippingbox.and.arrow.backward") {
                showingError = true
            }
        }
    }
    
//    MARK: Header/Footers
    @ViewBuilder
    private func makePageHeader() -> some View {
        UniversalText(index.getFullName(), size: Constants.UITitleTextSize, font: Constants.titleFont)
        UniversalText( RecallModel.ownerID, size: Constants.UISmallTextSize, font: Constants.mainFont )
    }
    
    @ViewBuilder
    private func makePageFooter() -> some View {
        HStack {
            LargeRoundedButton( "Edit", icon: "arrow.right", wide: true ) { showingEditingView = true }
//            LargeRoundedButton( "Transfer Data", icon: "arrow.right", wide: true ) { showingDataTransfer = true }
            LargeRoundedButton("Signout", icon: "arrow.down", wide: true) {
                RecallModel.realmManager.logoutUser()
                appPage = .splashScreen
            }
        }
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            makePageHeader()
                .padding(.bottom)
            
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    makeDemographicInfo()
                    
                    makeSettings()
                        .padding(.bottom, 40)
                    
                    Spacer()
                    
                    makePageFooter()
                        .padding(.bottom, 20)
                }
            }
        }
        .padding(7)
        .universalBackground()
        .alert("OwnerID", isPresented: $showingDataTransfer) {
            TextField("ownerID", text: $ownerID)
            Button(role: .destructive) {
                RecallModel.realmManager.transferDataOwnership(to: ownerID)
            } label: { Text("Transfer Data") }
        }
        .alert("Are you sure you want to delete your profile?", isPresented: $showingError) {
            Button(role: .destructive) {
                Task {
                    RecallModel.realmManager.logoutUser()
                    await RecallModel.realmManager.deleteProfile()
                }
            } label: { Text( "delete profile" ) }
        }
        .sheet(isPresented: $showingEditingView) {
            ProfileEditorView(email: index.email,
                              phoneNumber: index.phoneNumber,
                              dateOfBirth: index.dateOfBirth,
                              firstName: index.firstName,
                              lastName: index.lastName)
        }
        
    }
    
}
