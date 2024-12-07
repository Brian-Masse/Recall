//
//  WidgetManager.swift
//  Recall-WidgetExtension
//
//  Created by Brian Masse on 12/13/24.
//

import Foundation
import SwiftUI
import WidgetKit

class WidgetManager {
    
    static let shared = WidgetManager()
    
    private let mostRecentFavorite: RecallCalendarEvent? = nil
    
    func checkMostRecentfavorite(against: RecallCalendarEvent) {
//        if 
        
        
    }
    
    
//    MARK: updateWidgetData
//    This function is called anytime an event changes, and that even is to be used in a widget
//    ie. if a user favorites / unfavorites an event, it may run this function if the most recent favorite event changes
//    This function is here to centralize the updating of widget information
    @MainActor
    func updateWidgetData(for event: RecallCalendarEvent, key: String, widget: WidgetStorageKeys.widgets) {
        let widgetEvent = event.createWidgetEvent()
        
        WidgetStorage.shared.saveEvent(widgetEvent, for: key)
        
        WidgetCenter.shared.reloadTimelines(ofKind: widget.rawValue)
    }
    
    
    
}
