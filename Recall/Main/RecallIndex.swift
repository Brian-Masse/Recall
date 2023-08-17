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
class RecallIndex: Object, Identifiable {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted private(set) var earliestEventDate: Date = .now - (7 * Constants.DayTime)
//    @Persisted private(set) var templates: List<RecallCalendarEvent> = List()
    
    convenience init( ownerID: String ) {
        self.init()
        self.ownerID = ownerID
    }
    
    func updateEarliestEventDate(with date: Date) {
        self.earliestEventDate = date
    }
    
//    func addTemplate(_ newTemplate: RecallCalendarEvent) {
//        if let _ = self.templates.first(where: { event in
//            event.title == newTemplate.title
//        }) { return }
//        
//        if let copy: RecallCalendarEvent = RealmManager.retrieveObject(where: { event in event.title == newTemplate.title }).first {
//            RealmManager.updateObject(self) { thawed in
//                thawed.templates.append(copy)
//            }
//        }
//    }
//    
//    func removeTemplate(_ template: RecallCalendarEvent) {
//        if let index = self.templates.firstIndex(where: {event in
//            event.title == template.title
//        }) {
//            RealmManager.updateObject(self) { thawed in
//                thawed.templates.remove(at: index)
//            }
//        }
//    }
}
