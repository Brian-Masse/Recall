//
//  RecallIndex.swift
//  Recall
//
//  Created by Brian Masse on 7/20/23.
//

import Foundation
import RealmSwift


//Each user will have one of these objects stored under their profile in the database
//It is used for storing universal constants, such as the earliest event
//Later I plan to use it to store abreiviated data marks, so Im not forced into downloading every event on every boot
class RecallIndex: Object, Identifiable, OwnedRealmObject {
    
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
    
    @Persisted var finishedTutorial: Bool = false
    
    convenience init( ownerID: String, email: String, firstName: String, lastName: String) {
        self.init()
        self.ownerID = ownerID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        
        
        Task {
            await initializeIndex()
        }
    }
    
//    MARK: Class Methods
    func updateEarliestEventDate(with date: Date) {
        self.earliestEventDate = date
    }
    
    func update( firstName: String, lastName: String, email: String, phoneNumber: Int, dateOfBirth: Date ) {
        RealmManager.updateObject(self) { thawed in
            thawed.firstName = firstName
            thawed.lastName = lastName
            thawed.email = email
            thawed.phoneNumber = phoneNumber
            thawed.dateOfBirth = dateOfBirth
        }
    }
    
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
    
//    MARK: Convenience Functions
    
    func getFullName() -> String {
        "\(firstName) \(lastName)"
    }
    
    
//    MARK: Indexing Functions
    
//    this takes care of all the indexxing / constructing that needs to be done when a user first signs in.
//    It can also be used as a reset, if a user needs to manually reindex their data
    @MainActor
    private func initializeIndex() async {
    
//        let goals: [RecallGoal] = RealmManager.retrieveObjects()
//        let events: [RecallCalendarEvent] = RealmManager.retrieveObjects()
     
        
//        this function was initially designed to run setup on the goalProgressHistoryIndex on init
//        however, the function that gets the progress automatically creates an index if it doesn't find one,
//        meaning that the index sort of forms itself
        
    }
    
    
}
