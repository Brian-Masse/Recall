//
//  CalendarComponent.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift

class RecallCalendar: Object {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var ownerID: String
    
}

class RecallCalendarComponent: Object {
    
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted var title: String = ""
    
    convenience init(title: String) {
        self.init()
        
        self.title = title
    }
    
}

