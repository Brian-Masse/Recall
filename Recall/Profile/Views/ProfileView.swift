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
    @Environment(\.colorScheme) var colorScheme
    @Namespace var profileNamespace
    
    @ObservedObject private var colors = Colors.shared
    @ObservedObject private var coordinator = RecallNavigationCoordinator.shared
    
    @State var showingDataTransfer: Bool = false
    @State var ownerID: String = ""
    
//    When changing items in settings, set these to true to display a save button. This makes edditing settings more seamless.
    @State var madeNotificationChanges: Bool = false
    @State var madeDefaultEventLengthChanges: Bool = false
    
//    MARK: Temporary Settings
//    temporary settings: change these before committing them to the index when users hit save
    @ObservedRealmObject var index = RecallModel.index
    
    @State var notificationsEnabled: Bool = RecallModel.index.notificationsEnabled
    @State var notificationTime: Date = RecallModel.index.notificationsTime
    @State var showingNotificationToggle: Bool = true
    
    @State var defaultEventLength: Double = RecallModel.index.defaultEventLength
    
    @State var activeIcon: String = UIApplication.shared.alternateIconName ?? "light"
    
    @State var showingError: Bool = false
    @State private var showingTestView: Bool = false
    
//    MARK: Methods
    private func saveSettings() {
        index.toggleNotifcations(to: notificationsEnabled, time: notificationTime)
        madeNotificationChanges = false
    }
    
    
//    MARK: Constants
    struct SettingsConstants {
    
//        events
        static var showNotesOnPreviewLabel = "Show event notes on preview"
        
        static var defaultTimeSnappingLabel = "Default event snapping"
        
        static var recallAtEndOfLastEvent = "Moving Recall"
        static var recallAtEndOfLastEventDescription = "When enabled, each Recall starts at the end of the last event."
        
        static var automaticLocation = "Automatic Location"
        static var automaticLocationdescription = "When enabled, events will automatically save your current location."
        
        static var recallStyleLabel = "Default Recall Style"
        
//        notifications
        static var notificationsDisabledWarning = "Notifications are disabled, enable them in settings"
        static var notificationTimeSelectionLabel = "When would you like to be reminded?"
        
        static var deletionWarning = "Are you sure you want to delete your profile?"
    }
    
//    MARK: Bindings
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
    
    private var automaticLocationBinding: Binding<Bool> {
        Binding { index.automaticLocation }
        set: { newValue in index.setAutomaticLocation(to: newValue) }
    }
    
//    MARK: makeNotificationMessage
    private func makeNotificationMessage() async -> String {
        let settings = await NotificationManager.shared.getNotificationStatus()
        switch settings {
        case .denied:   return ""
        default: return ""
        }
    }
    
//    MARK: checkNotificationStatus
//    gets the current notification status from the notification manager
    @MainActor
    private func checkNotificationStatus() async {
        let status = await NotificationManager.shared.getNotificationStatus()
        showingNotificationToggle = (status != .denied)
    }

    
//    MARK: makeContactLabel
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
    
//    MARK: makeDemographicLabel
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

//    MARK: makeDemographicInfo
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
            makeSectionHeader("number", title: "Overview")
            
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
                
                if index.phoneNumber != 0 {
                    makeContactLabel(title: "phone number", content: "\(index.phoneNumber.formatIntoPhoneNumber())")
                }
            }
            .rectangularBackground(7, style: .secondary, stroke: true, strokeWidth: 1)
        }
    }

//    MARK: makeSettingsDescription
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
            
            makeSectionHeader("calendar.day.timeline.left", title: "Calendar")
            
            makeCalendarDisplayOptions()
                .rectangularBackground(style: .secondary, stroke: true, strokeWidth: 1)
                .padding(.bottom, 20)
                
            
            makeSectionHeader("widget.small", title: "Events")
            
            makeEventSettings()
                .rectangularBackground(style: .secondary, stroke: true, strokeWidth: 1)
                .padding(.bottom, 20)
            
            makeSectionHeader("circle.circle", title: "Appearance")
            
            makeAccentColorPicker()
                .rectangularBackground(style: .secondary, stroke: true, strokeWidth: 1)
                .padding(.bottom, 20)
            
            
            makeSectionHeader("app.badge", title: "Notifications")
            
            makeReminderSettings()
                .rectangularBackground(style: .secondary, stroke: true, strokeWidth: 1)
                .padding(.bottom, 20)
            
            makeSectionHeader("person.bust", title: "Account")
            
            makeActionButtons()
            
            makePageFooter()
                .padding(.bottom)
        }
    }
    
//    MARK: makeDefaultTimeSnappingSelector =
    @ViewBuilder
    private func makeDefaultTimeSnappingSelector() -> some View {
        UniversalText(SettingsConstants.defaultTimeSnappingLabel, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
        HStack {
            ForEach( TimeRounding.allCases ) { content in
                makeTimeSnappingSelector(title: content.getTitle(), option: content)
            }
        }
    }
    
//    MARK: makeCalendarDensityOption
    @ViewBuilder
    private func makeCalendarDensityOption(_ option: Int, caption: String) -> some View {
        
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
                    .foregroundStyle( index.calendarDensity == option ? Colors.getAccent(from: colorScheme) : .clear )
            }
            .onTapGesture { withAnimation {
                index.setCalendarDensity(to: option)
            } }
    }
    
//    MARK: makeCalendarDensitySelector
    @ViewBuilder
    private func makeCalendarDensitySelector() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "Calendar Density", size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            
            HStack(spacing: 0) {
                makeCalendarDensityOption(0, caption: "compact")
                makeCalendarDensityOption(1, caption: "regular")
                makeCalendarDensityOption(2, caption: "roomy")
            }
        }
    }
    
//    MARK: CalendarColoumnCountSelector
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
    private func makeCalendarColoumnCountSelector() -> some View {
        VStack(alignment: .leading) {
            UniversalText( "Coloumns", size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            
            HStack(spacing: 10) {
                makeCalendarColoumnCountOption(1, icon: "rectangle")
                makeCalendarColoumnCountOption(2, icon: "rectangle.split.2x1")
                makeCalendarColoumnCountOption(3, icon: "rectangle.split.3x1")
            }
        }
    }
    
//    MARK: - makeCalendarDisplayOptions
    @ViewBuilder
    private func makeCalendarDisplayOptions() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            makeCalendarDensitySelector()
            
            makeCalendarColoumnCountSelector()
        }
    }
    
//    MARK: makeDefaultEventLengthSelector
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
    
//    MARK: makeTimeSnappingSelector
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
    
//    MARK: makeEventSettings
    @ViewBuilder
    private func makeEventSettings() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            makeDefaultEventLengthSelector()
                .onChange(of: defaultEventLength) {
                    if defaultEventLength != RecallModel.index.defaultEventLength { madeDefaultEventLengthChanges = true }
                    else { madeDefaultEventLengthChanges = false }
                }
            
            Divider()
            
//        toggles
            StyledToggle(showingNotesOnPreviewBinding) {
                UniversalText( SettingsConstants.showNotesOnPreviewLabel, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            }
            
            StyledToggle(recallAtTheEndOfLastEventBinding) {
                UniversalText( SettingsConstants.recallAtEndOfLastEvent, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            }
            makeSettingsDescription(SettingsConstants.recallAtEndOfLastEventDescription)
            
            StyledToggle(automaticLocationBinding) {
                UniversalText( SettingsConstants.automaticLocation, size: Constants.UIDefaultTextSize, font: Constants.titleFont)
            }
            makeSettingsDescription(SettingsConstants.automaticLocationdescription)
            
            Divider()
            
            makeDefaultTimeSnappingSelector()
            
        }
    }
    
//    MARK: makeReminderSettings
    @ViewBuilder
    private func makeReminderSettings() -> some View {
        
        VStack(alignment: .leading) {
            StyledToggle($notificationsEnabled) {
                UniversalText( "Daily reminder", size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            }
            .onAppear { Task { await checkNotificationStatus() } }
            .onChange(of: notificationsEnabled) {
                
                if notificationsEnabled {
                    Task {
                        let results = await NotificationManager.shared.requestNotifcationPermissions()
                        notificationsEnabled = results
                        await checkNotificationStatus()
                    }
                }
                
                madeNotificationChanges = (notificationsEnabled != index.notificationsEnabled)
            }
            
            if !showingNotificationToggle {
                UniversalText( SettingsConstants.notificationsDisabledWarning, size: Constants.UISmallTextSize, font: Constants.mainFont )
            }
            
            if notificationsEnabled {
                TimeSelector(label: "", time: $notificationTime, size: Constants.UIDefaultTextSize)
                    .onChange(of: notificationTime) {
                        madeNotificationChanges = !( notificationTime.matches(index.notificationsTime, to: .minute) && notificationTime.matches(index.notificationsTime, to: .hour) )
                    }
            }
            
            if madeNotificationChanges {
                ConditionalLargeRoundedButton(title: "save", icon: "arrow.forward") { madeNotificationChanges
                } action: { saveSettings() }
            }
        }
    }
    
//    MARK: Color Preferences
    
    
    
//    MARK: makeAccentColorOption
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
            withAnimation { self.index.setAccentColor(to: index) }
        }
    }
    
//    MARK: makeAccentColorPicker
    @ViewBuilder
    private func makeAccentColorPicker() -> some View {
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
        .frame(height: 250)
    }
    
    
    
//    MARK: Header/Footers
    @ViewBuilder
    private func makePageHeader() -> some View {
        HStack {
            UniversalText(index.getFullName(), size: Constants.UIHeaderTextSize, font: Constants.titleFont)
            Spacer()
            
            DismissButton()
        }
    }
    
    @ViewBuilder
    private func makePageFooter() -> some View {
        VStack {
            HStack {
                IconButton("pencil", label: "Edit", fullWidth: true) { coordinator.presentSheet(.indexEditingView(index: index)) }
                IconButton("arrow.down", label: "Signout", fullWidth: true) {
                    await RecallModel.realmManager.logoutUser()
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
                RecallModel.realmManager.setState(.onboarding)
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
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    makeDemographicInfo()
                        .padding(.bottom, 20)
                    
                    makeSettings()
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    UniversalText( RecallModel.ownerID, size: Constants.UISmallTextSize, font: Constants.mainFont )
                        .padding(.bottom)
                        .onTapGesture { showingTestView = true }
                        .fullScreenCover(isPresented: $showingTestView) {
                            OnboardingView()
                        }
                }
            }
        }
        .animation(.easeInOut, value: index)
        
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
                    await RecallModel.realmManager.logoutUser()
                    await RecallModel.realmManager.deleteProfile()
                }
            } label: { Text( "delete profile" ) }
        }
    }
}

