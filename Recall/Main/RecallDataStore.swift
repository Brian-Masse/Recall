//
//  RecallDataStore.swift
//  Recall-WidgetExtension
//
//  Created by Brian Masse on 12/14/24.
//

import Foundation
import SwiftUI
import RealmSwift
import WidgetKit

class RecallDataStore: Object {
    
//    MARK: Vars
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var ownerID: String
    
//    MARK: mostRecentFavoriteWidget
    @Persisted var mostRecentFavoriteEventId: ObjectId? = nil
    
    func getMostRecentFavoriteEvent() -> RecallCalendarEvent? {
        if mostRecentFavoriteEventId == nil { return nil }
        return RecallCalendarEvent.getRecallCalendarEvent(from: mostRecentFavoriteEventId!)
    }
    
    @MainActor
    private func updateMostRecentEvent(with mostRecentFavoriteEvent: RecallCalendarEvent) {
        RealmManager.updateObject(self) { thawed in
            thawed.mostRecentFavoriteEventId = mostRecentFavoriteEvent._id
        }
    }
    
//    find the most recent favorite event
    @MainActor
    private func setMostRecentFavoriteEvent() async {
        let results: [RecallCalendarEvent] = RealmManager.retrieveObjects()
        
        let filteredResults = results
            .filter { $0.isFavorite }
            .sorted { $0.startTime > $1.startTime }
        
        if let mostRecentFavoriteEvent = filteredResults.first {
            updateMostRecentEvent(with: mostRecentFavoriteEvent)
        }
    }
    
//    when an event's favorite status changes, check whether it is now the mot recent favorite event
    @MainActor
    func checkMostRecentFavoriteEvent(against event: RecallCalendarEvent, isFavorite: Bool) {
        if isFavorite {
            let mostRecentEvent = getMostRecentFavoriteEvent()
            if event.startTime > mostRecentEvent?.startTime ?? .distantPast {
                updateMostRecentEvent(with: event)
            }
        } else {
            Task { await setMostRecentFavoriteEvent() }
        }
    }
}
