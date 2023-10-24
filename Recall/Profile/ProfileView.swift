//
//  ProfileView.swift
//  Recall
//
//  Created by Brian Masse on 8/21/23.
//

import Foundation
import SwiftUI
import RealmSwift

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
        
        static var universalFineSelectionLabel = "Universal fine time selection"
        static var universalFineSelectionDescription = "All time sliders will default to fine selection when enabled."
        
        static var defaultTimeSnappingLabel = "Default event snapping"
        static var defaultTimeSnappingDescription = "These are the time segments used when resizing events on the calendar and Recall pages."
        
//        notifications
        static var notificationsDisabledWarning = "Notifications are disabled, enable them in settings"
        static var notificationTimeSelectionLabel = "When would you like to be reminded?"
        
//        extra
        static var deletionWarning = "Are you sure you want to delete your profile?"
    }
    
    
//    MARK: Overview
    
    
    
//    MARK: OverviewViewBuilders
//    these are the buttons that appear below the main settings
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
    
//    these are the indivudal nodes that make up the contact section
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
            .secondaryOpaqueRectangularBackground()
            
            UniversalText( tertiaryText, size: Constants.UISmallTextSize, font: Constants.mainFont )
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
    
    
    
//    MARK: Settings ViewBuilders
    @ViewBuilder
    private func makeSettingsDivider() -> some View {
        Rectangle()
            .frame(height: 1)
            .universalTextStyle()
            .opacity(0.85)
    }
    
//    if a certain setting needs to be described more, use this description block
    private func makeSettingsDescription(_ text: String) -> some View {
        UniversalText( text, size: Constants.UISmallTextSize, font: Constants.mainFont )
            .padding(.leading, 5)
            .padding( [.bottom, .trailing] )
    }
    
//    MARK: Settings Body
    @ViewBuilder
    private func makeSettings() -> some View {
        
        VStack(alignment: .leading) {
            
            UniversalText( "Settings", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            
            VStack(alignment: .leading) {
                makeEventSettings()
                    .padding(.bottom)
                
                makeSettingsDivider()
                
                makeReminderSettings()
                    .padding(.bottom)
                
                makeSettingsDivider()
                
                makeIconSettings()
                
            }
            .opaqueRectangularBackground(stroke: true)
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
    
//    MARK: Event Settings ViewBuilders
    
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
    private func makeDefaultEventLengthSelector() -> some View {
        VStack(alignment: .leading) {
            SliderWithPrompt(label: "Default Event Length",
                             minValue: 0,
                             maxValue: Float(5 * Constants.HourTime),
                             binding: eventLengthBinding,
                             strBinding: eventLengthTitleBinding,
                             textFieldWidth: 150,
                             size: Constants.UIDefaultTextSize)
            
            if madeDefaultEventLengthChanges {
                ConditionalLargeRoundedButton(title: "save", icon: "arrow.forward") { madeDefaultEventLengthChanges } action: {
                    RecallModel.index.setDefaultEventLength(to: defaultEventLength)
                    madeDefaultEventLengthChanges = false
                }
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
            .if(option.rawValue == index.defaultEventSnapping) { view in view.tintRectangularBackground() }
            .if(option.rawValue != index.defaultEventSnapping) { view in view.secondaryOpaqueRectangularBackground() }
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
    
    
//    MARK: Event Settings Body
    @ViewBuilder
    private func makeEventSettings() -> some View {
        
        UniversalText( "Events", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            .padding(.vertical, 5)
            .onChange(of: defaultEventLength) { newValue in
                if newValue != RecallModel.index.defaultEventLength { madeDefaultEventLengthChanges = true }
                else { madeDefaultEventLengthChanges = false }
            }
    
        makeDefaultEventLengthSelector()
            .padding(.bottom)
        
//        toggles
        StyledToggle(showingNotesOnPreviewBinding) {
            UniversalText( SettingsConstants.showNotesOnPreviewLabel, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        }
        .padding(.bottom, 5)
        
        StyledToggle(fineTimeSelectorIsDefault) {
            UniversalText(SettingsConstants.universalFineSelectionLabel, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        }
        makeSettingsDescription(SettingsConstants.universalFineSelectionDescription)
        
        makeDefaultTimeSnappingSelector()
        makeSettingsDescription(SettingsConstants.defaultTimeSnappingDescription)
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
        
        UniversalText( "Reminders", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
            .padding(.top, 5)
            .onAppear { Task { await checkStatus() } }
        
        StyledToggle($notificationsEnabled) {
            UniversalText( "Daily reminder", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        }
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
            TimeSelector(label: SettingsConstants.notificationTimeSelectionLabel, time: $notificationTime, size: Constants.UIDefaultTextSize)
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
        UniversalText( "Icon", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
        
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
    }
    
    @ViewBuilder
    private func makePageFooter() -> some View {
        VStack {
            HStack {
                LargeRoundedButton( "Edit", icon: "arrow.right", wide: true ) { showingEditingView = true }
                LargeRoundedButton("Signout", icon: "arrow.down", wide: true) {
                    RecallModel.realmManager.logoutUser()
                    appPage = .splashScreen
                }
            }
            .padding(.bottom)
            
            UniversalText( RecallModel.ownerID, size: Constants.UISmallTextSize, font: Constants.mainFont )
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
