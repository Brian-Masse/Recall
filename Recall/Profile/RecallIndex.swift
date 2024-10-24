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
    
//    credentials
    @Persisted var email: String = ""
    @Persisted var firstName: String = ""
    @Persisted var lastName: String = ""
    @Persisted var phoneNumber: Int
    
    @Persisted var dateOfBirth: Date = .now
    @Persisted var dateJoined: Date = .now
    
    
    //  Settings
    @Persisted var finishedTutorial: Bool = false
    
    ///measured in miliseconds (able to directly be added to dates)
    @Persisted var defaultEventLength: Double = Constants.HourTime * 0.75
    @Persisted var showNotesOnPreview: Bool = true
    @Persisted var defaultFineTimeSelector: Bool = false
    @Persisted var defaultEventSnapping: Int = TimeRounding.quarter.rawValue
    @Persisted var recallEventsAtEndOfLastRecall: Bool = true
    @Persisted var recallEventsWithEventTime: Bool = true
    
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
        
        
        Task {
            await initializeIndex()
            await indexEvents()
        }
    }
    
    @MainActor
    func onAppear() {
        self.toggleNotifcations(to: self.notificationsEnabled, time: self.notificationsTime)
        
        Task {
            await indexEvents()
        }
    }
    
//    MARK: Class Methods
    func updateEarliestEventDate(with date: Date) {
        self.earliestEventDate = date
    }
    
    func daysSinceFirstEvent() -> Int {
        Int(Date.now.timeIntervalSince(earliestEventDate) / (Constants.DayTime))
    }
    
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
        self.phoneNumber != 0
    }
    
//    MARK: Tutorial
    func finishTutorial() {
        RealmManager.updateObject(self) { thawed in
            thawed.finishedTutorial = true
        }
    }
    
    func replayTutorial() {
        RealmManager.updateObject(self) { thawed in
            thawed.finishedTutorial = false
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
    
    
//    MARK: Notifications
    @MainActor
//    if you are turning the notifications on, it will handle notification requests, as well as setting up the actual notifiations
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
    
    @MainActor
    private func setNotificationTime(to time: Date) {
        RealmManager.updateObject(self) { thawed in
            thawed.notificationsTime = time
            
            NotificationManager.shared.makeNotificationRequest(from: time)
        }
    }
    
//    MARK: Events
    
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
    
    @MainActor
    func setDefaultRecallStyle(to value: Bool) {
        RealmManager.updateObject(self) { thawed in
            thawed.recallEventsWithEventTime = value
        }
    }
    
    @MainActor
    func setCalendarDensity(to value: Int) {
        RealmManager.updateObject(self) { thawed in
            withAnimation { thawed.calendarDensity = value }
        }
        
        RecallCalendarViewModel.shared.getScale(from: value)
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
    
//    MARK: Convenience Functions
    
    func getFullName() -> String {
        "\(firstName) \(lastName)"
    }
    
//    when accessing the defaultDateSnapping variable somtimes it is conveinient to get the rawValue
//    sometimes its conveinient to get the actual enum.
    var dateSnapping: TimeRounding {
        TimeRounding(rawValue: defaultEventSnapping) ?? .quarter
    }
    
    
//    MARK: Indexing Functions
    
//    this takes care of all the indexxing / constructing that needs to be done when a user first signs in.
//    It can also be used as a reset, if a user needs to manually reindex their data
    @MainActor
    func initializeIndex() async {
    
        let goals: [RecallGoal] = RealmManager.retrieveObjects()
        let events: [RecallCalendarEvent] = RealmManager.retrieveObjects()
        
        let startDate = earliestEventDate
        
//       for every day since the user created an account, this computes whether or not all of the goals were met
//       this is destructive in the sens that it will overrite all the current indecies
//       although the getProgress function on the goals can create these nodes if they are missing, this does it more optimatllt, storage wise
        await reindexGoalWasMetHistory(startDate: startDate, events: events, goals: goals)
        
    }
    
    
//    This should be run as little as possible, since it is so computationally expensive.
    func reindexGoalWasMetHistory(startDate: Date, events: [RecallCalendarEvent], goals: [RecallGoal]) async {
        var iterator = startDate
        var dateCounter: Int = 0
        
        while iterator <= ( Date.now.resetToStartOfDay() + Constants.DayTime ) {
            for goal in goals {
                let progress = await goal.computeGoalProgress(on: iterator, from: events)
                if let _ = await goal.retrieveProgressIndex(on: iterator) {
                    await goal.updateProgressIndex(to: progress, on: iterator)
                    
                } else {
                    await goal.makeNewProgressIndex(with: progress, on: iterator)
                }
                
                
            }
            iterator += Constants.DayTime
            dateCounter += 1
        }
    }
    
    @MainActor
    private func eraseGoalIndex(_ goal: RecallGoal) {
        RealmManager.updateObject(goal) { thawed in
            goal.indexedGoalProgressHistory = List()
        }
    }
    
//    MARK: Color
    func updateAccentColor(to index: Int? = nil) {
        let accentColor = Colors.accentColorOptions[index ?? self.recallAccentColorIndex]
        let mixValue = accentColor.mixValue
        
        Colors.setColors(secondaryLight: Colors.defaultSecondaryLight.safeMix(with: accentColor.lightAccent, by: mixValue),
                         secondaryDark: Colors.defaultSecondaryDark.safeMix(with: accentColor.darkAccent, by: mixValue),
                         lightAccent: accentColor.lightAccent,
                         darkAccent: accentColor.darkAccent)
    }
    
    
//    MARK: EventsIndex
    @Persisted private var eventsIndexUpToDate: Bool = false
    @Persisted var eventsIndex = Map<String, Int>()
    
    @MainActor
    func addEventToIndex( on date: Date ) {
        let key = date.getDayKey()
        let count = eventsIndex[key] ?? 0
        
        RealmManager.updateObject(self) { thawed in
            thawed.eventsIndex[key] = count + 1
        }
    }
    
    @MainActor
    func removeEventFromIndex( on date: Date ) {
        let key = date.getDayKey()
        let count = eventsIndex[key] ?? 0
        
        if count > 0 {
            RealmManager.updateObject(self) { thawed in
                thawed.eventsIndex[key] = count - 1
            }
        }
    }
    
    @MainActor
    func updateEventsIndex( oldDate: Date, newDate: Date ) {
        removeEventFromIndex(on: oldDate)
        removeEventFromIndex(on: newDate)
    }
    
    @MainActor
    func indexEvents() async {
        if eventsIndexUpToDate { return }
        
        RealmManager.updateObject(self) { thawed in
            thawed.eventsIndex = Map<String, Int>()
        }
        
        let events: [RecallCalendarEvent] = RealmManager.retrieveObjects()
        
        for event in events {
            addEventToIndex(on: event.startTime)
        }
        
        RealmManager.updateObject(self) { thawed in
            thawed.eventsIndexUpToDate = true
        }
    }
    
    
//    MARK: reindex
//    these sets of functions react to the ways an event can be updated, and consequently effect the goalProgress index
    func updateEvent(_ event: RecallCalendarEvent) async {
        
        @MainActor
        func getStartTime() -> Date { event.startTime }
        
        var iterator = await getStartTime()
        let endDate = iterator + (7 * Constants.DayTime)
        
        let goals = await event.getGoals()
        let events: [RecallCalendarEvent] = await RealmManager.retrieveObjects()
        
        while iterator <= endDate {
            
            for goal in goals {
                
                let newProgress = await goal.computeGoalProgress(on: iterator, from: events)
                await goal.updateProgressIndex(to: newProgress, on: iterator)
            }
            iterator += Constants.DayTime
        }
        print("finished updating goal Index")
    }
}
