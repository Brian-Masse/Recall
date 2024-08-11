//
//  ProfileView.swift
//  Recall
//
//  Created by Brian Masse on 8/21/23.
//

import Foundation
import SwiftUI
import RealmSwift
import UIUniversals

@MainActor
struct ProfileView: View {
    
//    MARK: Vars
    @Namespace var profileNamespace
    
    @State var showingDataTransfer: Bool = false
    @State var showingEditingView: Bool = false
    @State var ownerID: String = ""
    
//    When changing items in settings, set these to true to display a save button. This makes edditing settings more seamless.
    @State var madeNotificationChanges: Bool = false
    @State var madeDefaultEventLengthChanges: Bool = false
    
//    temporary settings: change these before committing them to the index when users hit save
    @ObservedRealmObject var index = RecallModel.index
    
    @State var notificationsEnabled: Bool = RecallModel.index.notificationsEnabled
    @State var notificationTime: Date = RecallModel.index.notificationsTime
    @State var showingNotificationToggle: Bool = true
    
    @State var defaultEventLength: Double = RecallModel.index.defaultEventLength
    
    @State var activeIcon: String = UIApplication.shared.alternateIconName ?? "light"
    
    @State var showingError: Bool = false
    
//    MARK: Methods
    private func saveSettings() {
        index.toggleNotifcations(to: notificationsEnabled, time: notificationTime)
        madeNotificationChanges = false
    }
    
    
//    MARK: Constants
    struct SettingsConstants {
    
//        events
        static var showNotesOnPreviewLabel = "Show event notes on preview"
        
        static var universalFineSelectionLabel = "Universal precise time selection"
        
        static var defaultTimeSnappingLabel = "Default event snapping"
        
        static var recallAtEndOfLastEvent = "Moving Recall"
        static var recallAtEndOfLastEventDescription = "When enabled, each Recall starts at the end of the last event."
        
        static var recallStyleLabel = "Default Recall Style"
        
//        notifications
        static var notificationsDisabledWarning = "Notifications are disabled, enable them in settings"
        static var notificationTimeSelectionLabel = "When would you like to be reminded?"
        
//        extra
        static var deletionWarning = "Are you sure you want to delete your profile?"
    }
    
    
//    MARK: Overview
    
    
    
//    MARK: OverviewViewBuilders
//    these are the indivudal nodes that make up the contact section
    @ViewBuilder
    private func makeContactLabel( title: String, content: String ) -> some View {
        HStack {
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            Spacer()
            UniversalText(content, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
                .opacity(0.75)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
    }
    
//    these are the big blocks that describe birthday and date joined
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
            .rectangularBackground(style: .primary)
            
            UniversalText( tertiaryText, size: Constants.UISmallTextSize, font: Constants.mainFont )
                .opacity(0.5)
        }
    }

//    MARK: OverviewBody
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
        
        
        VStack(alignment: .leading) {
            UniversalText( "Overview", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            VStack(alignment: .leading) {
                HStack {
                    makeDemographicLabel(mainText: dayFormatted.string(from: index.dateJoined),
                                         secondaryText: yearFormatted.string(from: index.dateJoined),
                                         tertiaryText: "Date Joined")
                    
                    makeDemographicLabel(mainText: dayFormatted.string(from: index.dateOfBirth),
                                         secondaryText: yearFormatted.string(from: index.dateOfBirth),
                                         tertiaryText: "Date of Birth")
                }.padding(.bottom)
                
                makeContactLabel(title: "email", content: index.email)
                makeContactLabel(title: "phone number", content: "\(index.phoneNumber.formatIntoPhoneNumber())")
            }
            .rectangularBackground(7, style: .secondary)
        }
    }
    
//    MARK: settings
    
    
    
//    MARK: Settings ViewBuilders
    @ViewBuilder
    private func makeSettingsDivider() -> some View {
        Rectangle()
            .frame(height: 1)
            .universalTextStyle()
            .opacity(0.6)
    }
    
//    if a certain setting needs to be described more, use this description block
    private func makeSettingsDescription(_ text: String) -> some View {
        UniversalText( text, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            .padding([.leading, .bottom, .trailing])
            .opacity(0.5)
    }
    
//    MARK: Settings Body
    @ViewBuilder
    private func makeSettings() -> some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( "Event Settings", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            
            makeEventSettings()
                .rectangularBackground(style: .secondary)
                .padding(.bottom, 20)
            
            UniversalText( "Reminders", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            
            makeReminderSettings()
                .rectangularBackground(style: .secondary)
                .padding(.bottom, 20)
            
            UniversalText( "Icon", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            
            makeIconSettings()
                .rectangularBackground(style: .secondary)
                .padding(.bottom, 20)
            
            UniversalText( "Account Settings", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
            
            makeActionButtons()
            
            makePageFooter()
                .padding(.bottom)
                
        }
    }
    
//    MARK: Event Settings ViewBuilders

    @ViewBuilder
    private func makeDefaultEventLengthSelector() -> some View {
        LengthSelector("Default Event Length",
                       length: $defaultEventLength,
                       fontSize: Constants.UIDefaultTextSize,
                       allowFineToggle: false)
        
        if madeDefaultEventLengthChanges {
            ConditionalLargeRoundedButton(title: "save", icon: "arrow.forward") { madeDefaultEventLengthChanges } action: {
                RecallModel.index.setDefaultEventLength(to: defaultEventLength)
                madeDefaultEventLengthChanges = false
            }
        }
    }
    
    private var showingNotesOnPreviewBinding: Binding<Bool> {
        Binding { index.showNotesOnPreview }
        set: { newValue in index.setShowNotesOnPreview(to: newValue) }
    }
    
    private var fineTimeSelectorIsDefault: Binding<Bool> {
        Binding { index.defaultFineTimeSelector }
        set: { newValue in index.setDefaultFineTimeSelector(to: newValue) }
    }
    
    private var recallAtTheEndOfLastEventBinding: Binding<Bool> {
        Binding { index.recallEventsAtEndOfLastRecall }
        set: { newValue in index.setRecallAtEndOfLastEvent(to: newValue) }
    }
    
    @ViewBuilder
    private func makeTimeSnappingSelector(title: String, option: TimeRounding) -> some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                Spacer()
                UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
                Spacer()
            }
            Spacer()
        }
        .if(option.rawValue == index.defaultEventSnapping) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
        .if(option.rawValue != index.defaultEventSnapping) { view in view.rectangularBackground(style: .primary) }
            .onTapGesture { withAnimation { index.setDefaultTimeSnapping(to: option) } }
    }
    
    @ViewBuilder
    private func makeDefaultTimeSnappingSelector() -> some View {
        UniversalText(SettingsConstants.defaultTimeSnappingLabel, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        HStack {
            ForEach( TimeRounding.allCases ) { content in
                makeTimeSnappingSelector(title: content.getTitle(), option: content)
            }
        }
    }
    
    private func makeDefaultRecallStyleSelectorOption(_ label: String, icon: String, option: Bool) -> some View {
        HStack {
            Spacer()
            VStack {
                Image(systemName: icon)
                    .padding(.bottom, 5)
                UniversalText(label, size: Constants.UISmallTextSize, font: Constants.mainFont)
            }
            Spacer()
        }
        .if( option == index.recallEventsWithEventTime ) { view in view.rectangularBackground(style: .accent, foregroundColor: .black) }
        .if( option != index.recallEventsWithEventTime ) { view in view.rectangularBackground(style: .primary) }
        .onTapGesture { withAnimation { index.setDefaultRecallStyle(to: option) } }
    }
    
    private func makeDefaultRecallStyleSelector() -> some View {
        
        VStack(alignment: .leading) {
            UniversalText( SettingsConstants.recallStyleLabel, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            HStack {
                makeDefaultRecallStyleSelectorOption("Recall with event time", icon: "calendar", option: true)
                makeDefaultRecallStyleSelectorOption("Recall with event length", icon: "rectangle.expand.vertical", option: false)
            }
            .padding(.bottom, 5)
        }
    }
    
    
//    MARK: Event Settings Body
    @ViewBuilder
    private func makeEventSettings() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            makeDefaultEventLengthSelector()
                .onChange(of: defaultEventLength) { newValue in
                    if newValue != RecallModel.index.defaultEventLength { madeDefaultEventLengthChanges = true }
                    else { madeDefaultEventLengthChanges = false }
                }
            
            makeSettingsDivider()
            
//        toggles
            StyledToggle(showingNotesOnPreviewBinding) {
                UniversalText( SettingsConstants.showNotesOnPreviewLabel, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            }
            
            StyledToggle(fineTimeSelectorIsDefault) {
                UniversalText(SettingsConstants.universalFineSelectionLabel, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            }
            
            StyledToggle(recallAtTheEndOfLastEventBinding) {
                UniversalText( SettingsConstants.recallAtEndOfLastEvent, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            }
            makeSettingsDescription(SettingsConstants.recallAtEndOfLastEventDescription)
            
            makeSettingsDivider()
            
            makeDefaultRecallStyleSelector()
            
            makeDefaultTimeSnappingSelector()
        }
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
        
        VStack(alignment: .leading) {
            StyledToggle($notificationsEnabled) {
                UniversalText( "Daily reminder", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            }
            .onAppear { Task { await checkStatus() } }
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
            
            if !showingNotificationToggle {
                UniversalText( SettingsConstants.notificationsDisabledWarning, size: Constants.UISmallTextSize, font: Constants.mainFont )
            }
            
            if notificationsEnabled {
                TimeSelector(label: "", time: $notificationTime, size: Constants.UIDefaultTextSize)
                    .onChange(of: notificationTime) { newValue in
                        madeNotificationChanges = !( newValue.matches(index.notificationsTime, to: .minute) && newValue.matches(index.notificationsTime, to: .hour) )
                    }
            }
            
            if madeNotificationChanges {
                ConditionalLargeRoundedButton(title: "save", icon: "arrow.forward") { madeNotificationChanges
                } action: { saveSettings() }
            }
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
                    .universalStyledBackgrond(.accent, onForeground: true)
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
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                makeIconPicker(icon: "light")
                Spacer()
                makeIconPicker(icon: "dark")
                Spacer()
            }
        }
    }
    
//    MARK: Header/Footers
    @ViewBuilder
    private func makePageHeader() -> some View {
        UniversalText(index.getFullName(), size: Constants.UITitleTextSize, font: Constants.titleFont)
    }
    
    @ViewBuilder
    private func makePageFooter() -> some View {
        VStack {
            HStack {
                IconButton("pencil", label: "Edit", fullWidth: true) { showingEditingView = true }
                IconButton("arrow.down", label: "Signout", fullWidth: true) {
                    RecallModel.realmManager.logoutUser()
                    RecallModel.realmManager.setState(.splashScreen)
                }
            }
            .padding(.bottom)
        }
    }
    
//    MARK: ActionButtons
    @ViewBuilder
    private func makeActionButtons() -> some View {
        VStack {
            IconButton("arrow.clockwise", label: "Replay Tutoria", fullWidth: true) {
                index.replayTutorial()
                RecallModel.realmManager.setState(.tutorial)
            }
            
            IconButton("tray.2", label: "Reindex Data", fullWidth: true) {
                Task { await RecallModel.index.initializeIndex() }
            }
            
            IconButton("shippingbox.and.arrow.backward", label: "Delete Account", fullWidth: true) {
                showingError = true
            }
            .foregroundStyle(.red)
        }
     }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
            makePageHeader()
                .padding(.bottom)
            
            ScrollView(.vertical) {
                VStack {
                    makeDemographicInfo()
                        .padding(.bottom, 20)
                    
                    makeSettings()
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    UniversalText( RecallModel.ownerID, size: Constants.UISmallTextSize, font: Constants.mainFont )
                        .padding(.bottom)
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
        .alert(SettingsConstants.deletionWarning, isPresented: $showingError) {
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
