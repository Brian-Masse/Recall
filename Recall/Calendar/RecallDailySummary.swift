//
//  RecallDailySummary.swift
//  Recall
//
//  Created by Brian Masse on 10/16/24.
//

import Foundation
import RealmSwift

class RecallDailySummary: Object, Identifiable {
    
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
    @Persisted var date: Date = .now
    @Persisted var notes: String = ""
    
    convenience init(date: Date, notes: String) {
        self.init()
        
        self.ownerID = RecallModel.ownerID
        self.date = date
        self.notes = notes
    }
    
    static func getSummary(on date: Date, from summaries: [RecallDailySummary]) async -> RecallDailySummary? {
        return summaries.first { $0.date.matches(date, to: .day) }
    }
}
