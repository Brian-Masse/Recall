//
//  RecallDataStore.swift
//  Recall-WidgetExtension
//
//  Created by Brian Masse on 12/14/24.
//

import Foundation
import SwiftUI
import RealmSwift

class RecallDataStore: Object {
    
//    MARK: Vars
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
//    MARK: mostRecentFavoriteWidget
    @Persisted private var mostRecentFavoriteEvent: RecallCalendarEvent? = nil
    
    
    
}
