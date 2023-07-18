//
//  CalendarComponent.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift

//class RecallCalendar: Object {
//
//    @Persisted(primaryKey: true) var _id: ObjectId
//    @Persisted var ownerID: String
//
//}

class RecallCalendarComponent: Object, Identifiable  {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted var title: String = ""
    
    @Persisted var startTime: Date = .now
    @Persisted var endTime:   Date = .now + Constants.HourTime
    
    convenience init(ownerID: String, title: String) {
        self.init()
        self.ownerID = ownerID
        self.title = title
    }
    
    func update( title: String, startDate: Date, endDate: Date ) {
        RealmManager.updateObject(self) { thawed in
            thawed.title = title
            
            thawed.startTime = startDate
            thawed.endTime = endDate
        }
    }
    
    func updateDate(startDate: Date? = nil, endDate: Date? = nil) {
        RealmManager.updateObject(self) { thawed in
            thawed.startTime = startDate ?? thawed.startTime
            thawed.endTime = endDate ?? thawed.endTime
        }
    }
    
//    MARK: Class Methods
    
}

