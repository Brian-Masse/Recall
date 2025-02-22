//
//  RecallIndex.swift
//  Recall
//
//  Created by Brian Masse on 7/20/23.
//

import Foundation
import RealmSwift
import UIUniversals
import SwiftUI
import WidgetKit


//Each user will have one of these objects stored under their profile in the database
//It is used for storing universal constants, such as the earliest event
//as well as preferences
//it is also used to index data, so as to improve the read speed of data and improve the
//overall performance of the app
class RecallIndex: Object, Identifiable, OwnedRealmObject {
    
//    MARK: Vars
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted private(set) var earliestEventDate: Date = .now - (7 * Constants.DayTime)
    
//    MARK: Credentials
//    credentials
    @Persisted var email: String = ""
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    @Persisted var phoneNumber: Int
    
    @Persisted var dateOfBirth: Date = .now
    @Persisted var dateJoined: Date = .now
    
    
//    MARK: Tutorial
    //  Settings
    @Persisted private var finishedTutorial: Bool = false
    @Persisted private var finishedOnboarding: Bool = false
    @Persisted private(set) var onBoardingState: Int = 0
    
    var onboardingComplete: Bool {
        self.finishedTutorial && self.finishedOnboarding
    }
    
//    MARK: Preferences
    ///measured in miliseconds (able to directly be added to dates)
    @Persisted var defaultEventLength: Double = Constants.HourTime * 0.75
    @Persisted var showNotesOnPreview: Bool = true
    @Persisted var defaultFineTimeSelector: Bool = false
    @Persisted var defaultEventSnapping: Int = TimeRounding.quarter.rawValue
    @Persisted var recallEventsAtEndOfLastRecall: Bool = true
    @Persisted var recallEventsWithEventTime: Bool = true
    @Persisted var automaticLocation: Bool = true
    
    @Persisted var calendarColoumnCount: Int = 1
    @Persisted var calendarDensity: Int = 0
    @Persisted var recallAccentColorIndex: Int = 0
    
    @Persisted var notificationsEnabled: Bool = false
    @Persisted var notificationsTime: Date = .now
    
//    MARK: Initializer
    convenience init( ownerID: String, email: String, firstName: String, lastName: String) {
        self.init()
        self.ownerID = ownerID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
    
//    MARK: OnAppear
    @MainActor
    func onAppear() {
        self.toggleNotifcations(to: self.notificationsEnabled, time: self.notificationsTime)
        if self.calendarColoumnCount == 0 { setCalendarColoumnCount(to: 2) }
    }
    
//    MARK: UpdateEarliestEventData
    func updateEarliestEventDate(with date: Date) {
        self.earliestEventDate = date
    }
    
//    MARK: Convenience Vars
    func daysSinceFirstEvent() -> Int {
        Int(Date.now.timeIntervalSince(earliestEventDate) / (Constants.DayTime))
    }
    
    func getFullName() -> String { "\(firstName) \(lastName)" }
    
//    when accessing the defaultDateSnapping variable somtimes it is conveinient to get the rawValue
//    sometimes its conveinient to get the actual enum.
    var dateSnapping: TimeRounding { TimeRounding(rawValue: defaultEventSnapping) ?? .quarter }
    
    
//    MARK: Update
    func update( firstName: String, lastName: String, email: String, phoneNumber: Int, dateOfBirth: Date ) {
        RealmManager.updateObject(self) { thawed in
            thawed.firstName = firstName
            thawed.lastName = lastName
            thawed.email = email
            thawed.phoneNumber = phoneNumber
            thawed.dateOfBirth = dateOfBirth
        }
    }
    
    func checkCompletion() -> Bool {
        !self.firstName.isEmpty &&
        !self.lastName.isEmpty &&
        !self.email.isEmpty &&
        self.onboardingComplete
    }
    
//    MARK: SetupDefaultProfile
//    Called during the creation of an index, before the index has been stored to realm
    func setupDefaultProfile(email: String) {
        self.ownerID = RecallModel.ownerID
        self.dateJoined = .now
        self.email = email
        
        self.calendarColoumnCount = 2
        self.calendarDensity = 2
    }
    
//    MARK: Tutorial
    func completeOnboarding() {
        RealmManager.updateObject(self) { thawed in
            thawed.finishedTutorial = true
            thawed.finishedOnboarding = true
            thawed.onBoardingState = OnBoardingScene.allCases.count
        }
    }
    
//    MARK: Replay Onboarding
    func replayOnboarding() {
        RealmManager.updateObject(self) { thawed in
            thawed.finishedTutorial = false
            thawed.finishedOnboarding = false
            thawed.onBoardingState = 0
        }
        
        Task { await RecallModel.realmManager.setState(.onboarding) }
    }
    
//    MARK: setOnboardingScene
    func setOnboardingScene(to sceneIndex: Int) {
        RealmManager.updateObject(self) { thawed in
            thawed.onBoardingState = sceneIndex
        }
    }
    
//    MARK: MostRecentRecall
    private(set) var mostRecentRecallTime: Date? = nil
    func getMostRecentRecallEnd( on date: Date ) -> Date {
        
        if let time = self.mostRecentRecallTime {
            if time.matches(date, to: .day) {
                return time
            }
        }

        return .now
    }
    
    func setMostRecentRecallEvent(to time: Date) {
        self.mostRecentRecallTime = time
    }
    
    
//    MARK: toggleNotifications
//    if you are turning the notifications on, it will handle notification requests, as well as setting up the actual notifiations
    @MainActor
    func toggleNotifcations(to enabled: Bool, time: Date) {
        
        if !enabled {
            RealmManager.updateObject(self) { thawed in
                thawed.notificationsEnabled = false
                NotificationManager.shared.clearNotifications()
            }
        } else {
            Task {
                let results = await NotificationManager.shared.requestNotifcationPermissions()
                
                RealmManager.updateObject(self) { thawed in
                    thawed.notificationsEnabled = results
                    if results { self.setNotificationTime(to: time) }
                }
            }
        }
    }
    
//    MARK: setNotificationTime
    @MainActor
    private func setNotificationTime(to time: Date) {
        RealmManager.updateObject(self) { thawed in
            thawed.notificationsTime = time
            
            NotificationManager.shared.makeNotificationRequest(from: time)
        }
    }
    
//    MARK: Events Settings
    @MainActor
    func setDefaultEventLength(to length: Double) {
        RealmManager.updateObject(self) { thawed in
            thawed.defaultEventLength = length
        }
    }
    
    @MainActor
    func setShowNotesOnPreview(to value: Bool) {
        RealmManager.updateObject(self) { thawed in
            thawed.showNotesOnPreview = value
        }
    }
    
//    deprecated
    @MainActor
    func setDefaultFineTimeSelector(to value: Bool) {
        RealmManager.updateObject(self) { thawed in
            thawed.defaultFineTimeSelector = value
        }
    }
    
    @MainActor
    func setRecallAtEndOfLastEvent(to value: Bool) {
        RealmManager.updateObject(self) { thawed in
            thawed.recallEventsAtEndOfLastRecall = value
        }
    }
    
    @MainActor
    func setDefaultTimeSnapping(to value: TimeRounding) {
        RealmManager.updateObject(self) { thawed in
            thawed.defaultEventSnapping = value.rawValue
        }
    }
    
//    deprecated
    @MainActor
    func setDefaultRecallStyle(to value: Bool) {
        RealmManager.updateObject(self) { thawed in
            thawed.recallEventsWithEventTime = value
        }
    }
    
    @MainActor
    func setAutomaticLocation(to value: Bool) {
        RealmManager.updateObject(self) { thawed in
            thawed.automaticLocation = value
        }
    }
    
    @MainActor
    func setCalendarDensity(to value: Int) {
        RealmManager.updateObject(self) { thawed in
            withAnimation { thawed.calendarDensity = value }
        }
        
        RecallCalendarContainerViewModel.shared.getScale(from: value)
    }
    
    func setCalendarColoumnCount(to value: Int) {
        RealmManager.updateObject(self) { thawed in
            withAnimation { thawed.calendarColoumnCount = value }
        }
        
        RecallCalendarContainerViewModel.shared.setDaysPerView(to: value)
    }
    
    @MainActor
    func setAccentColor(to value: Int) {
        RealmManager.updateObject(self) { thawed in
            thawed.recallAccentColorIndex = value
        }
        
        self.updateAccentColor(to: value)
    }
    
//    MARK: postProfileCreationInit
//    This runs after the user has created their profile, (in turn setting their name, number, email, and birthday)
//    some of the functions in this method are redundant
    @MainActor
    func postProfileCreationInit() {
        
        self.toggleNotifcations(to: true, time: notificationsTime )
        NotificationManager.shared.makeNotificationRequest(from: notificationsTime)
        NotificationManager.shared.makeBirthdayNotificationRequest(from:  dateOfBirth )
    }
    
//    MARK: Color
    func updateAccentColor(to index: Int? = nil) {
        let accentColor = Colors.accentColorOptions[index ?? self.recallAccentColorIndex]
        let mixValue = accentColor.mixValue

        let darkPrimary     = Colors.defaultPrimaryDark.safeMix(with: accentColor.darkAccent, by: 0.15)
        let lightPrimary    = Colors.defaultPrimaryLight.safeMix(with: accentColor.lightAccent, by: 0.01)
        
        let darkSecondary   = Colors.defaultSecondaryDark.safeMix(with: accentColor.darkAccent, by: mixValue)
        let lightSecondary  = Colors.defaultSecondaryLight.safeMix(with: accentColor.lightAccent, by: mixValue)
        
        Colors.setColors(baseLight: lightPrimary,
                         secondaryLight: lightSecondary,
                         baseDark: darkPrimary,
                         secondaryDark: darkSecondary,
                         lightAccent: accentColor.lightAccent ,
                         darkAccent: accentColor.darkAccent)
        
//        signal to the widgets that the accent color has chagned
        WidgetStorage.shared.saveColor(accentColor.lightAccent, for: WidgetStorageKeys.ligthAccent)
        WidgetStorage.shared.saveColor(accentColor.darkAccent, for: WidgetStorageKeys.darkAccent)
        WidgetStorage.shared.saveBasicValue(value: accentColor.mixValue, key: WidgetStorageKeys.mixValue)
        WidgetStorage.shared.saveBasicValue(value: true, key: WidgetStorageKeys.updateAccentColorTrigger)
        
        WidgetCenter.shared.reloadAllTimelines()
        
        OnboardingViewModel.shared.triggerBackgroundUpdate.toggle()
    }
}
