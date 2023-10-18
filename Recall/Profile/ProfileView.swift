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
    
//    When changing items in settings, set these to true to display a save button. This makes edditing settings more seamless.
    @State var madeNotificationChanges: Bool = false
    @State var madeDefaultEventLengthChanges: Bool = false
    
//    temporary settings: change these before committing them to the index when users hit save
    @State var notificationsEnabled: Bool = RecallModel.index.notificationsEnabled
    @State var notificationTime: Date = RecallModel.index.notificationsTime
    @State var showingNotificationToggle: Bool = true
    
    @State var defaultEventLength: Double = RecallModel.index.defaultEventLength
    
    
    
    @State var activeIcon: String = UIApplication.shared.alternateIconName ?? "light"
    
    @State var showingError: Bool = false
    
    let index = RecallModel.index
    
//    MARK: Methods
    private func saveSettings() {
        index.toggleNotifcations(to: notificationsEnabled, time: notificationTime)
        madeNotificationChanges = false
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
    private func makeSettings() -> some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( "Settings", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            
            VStack(alignment: .leading) {
                makeReminderSettings()
                    .padding(.bottom)
                
                makeEventSettings()
                
                makeIconSettings()
                
            }
            .opaqueRectangularBackground(7, stroke: true)
            .padding(.bottom, 5)
            
            makeSubButton(title: "Replay Tutorial", icon: "arrow.clockwise") {
                index.replayTutorial()
                appPage = .tutorial
            }
            
            makeSubButton(title: "reindex Data", icon: "tray.2") {
                Task { await RecallModel.index.initializeIndex() }
            }
            
            makeSubButton(title: "delete account", icon: "shippingbox.and.arrow.backward") {
                showingError = true
            }
        }
    }
    
//    MARK: Event Settings
    
    private var eventLengthBinding: Binding<Float> {
        Binding { Float(defaultEventLength) }
        set: { newValue in
            let multiplier = 15 * Constants.MinuteTime
            defaultEventLength = (Double( newValue ) / multiplier).rounded(.down) * multiplier
        }
    }
    
    private var eventLengthTitleBinding: Binding<String> {
        Binding {
            let hours = (defaultEventLength / Constants.HourTime)
            let hour = hours.rounded(.down)
            let minutes = ((hours - hour) * 60).rounded(.down)
            
            return "\( Int(hour) )hr \( Int(minutes) ) mins"
        } set: { _ in }
        
    }
    
    @ViewBuilder
    private func makeEventSettings() -> some View {
        
        
        UniversalText( "Events", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            .padding(.top, 5)
        
        SliderWithPrompt(label: "Default Event Length",
                         minValue: 0, 
                         maxValue: Float(5 * Constants.HourTime),
                         binding: eventLengthBinding,
                         strBinding: eventLengthTitleBinding,
                         textFieldWidth: 150,
                         size: Constants.UIDefaultTextSize)
        
    }
    
    
//    MARK: Notification Settings
    private func makeNotificationMessage() async -> String {
        let settings = await NotificationManager.shared.getNotificationStatus()
        switch settings {
        case .denied:   return ""
        default: return ""
        }
    }
     
    @MainActor
    private func checkStatus() async {
        let status = await NotificationManager.shared.getNotificationStatus()
        showingNotificationToggle = (status != .denied)
    }
    
    @ViewBuilder
    private func makeReminderSettings() -> some View {
        
        UniversalText( "Reminders", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            .padding(.top, 5)
            .onAppear { Task { await checkStatus() } }
        
        HStack {
            UniversalText( "Daily reminder", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            Spacer()
            if showingNotificationToggle {
                Toggle(isOn: $notificationsEnabled) { }
                    .tint(Colors.tint)
                    .onChange(of: notificationsEnabled) { newValue in
                        
                        if newValue {
                            Task {
                                let results = await NotificationManager.shared.requestNotifcationPermissions()
                                notificationsEnabled = results
                                await checkStatus()
                            }
                        }
                        
                        madeNotificationChanges = (newValue != index.notificationsEnabled)
                    }
            }
        }
        
        if !showingNotificationToggle {
            UniversalText( "Notifications are disabled, enable them in settings", size: Constants.UISmallTextSize, font: Constants.mainFont )
        }
        
        if notificationsEnabled {
            TimeSelector(label: "When would you like to be reminded?", time: $notificationTime, size: Constants.UIDefaultTextSize)
                .onChange(of: notificationTime) { newValue in
                    madeNotificationChanges = !( newValue.matches(index.notificationsTime, to: .minute) && newValue.matches(index.notificationsTime, to: .hour) )
                }
        }
        
        if madeNotificationChanges {
            ConditionalLargeRoundedButton(title: "save", icon: "arrow.forward") { madeNotificationChanges
            } action: { saveSettings() }
        }
    }
    
//    MARK: Icon Picker
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
        .onTapGesture {
            withAnimation { activeIcon = icon }
            UIApplication.shared.setAlternateIconName(icon) { error in
                if let err = error { print( err.localizedDescription ) }
            }
        }
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
