//
//  RecallModel.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI

//Main user ownerID
//64b8478c84023dfb762af304
let inDev = true

@MainActor
struct RecallModel {
    
    static let shared: RecallModel = RecallModel()
    static let realmManager: RealmManager = RealmManager()
    
    static var ownerID: String { RecallModel.realmManager.user?.id ?? "" }
    static var index: RecallIndex { RecallModel.realmManager.index  }
    
    let activeColor: Color = Colors.main
    
    static func getDaysSinceFirstEvent() -> Double {
        (Date.now.timeIntervalSince(index.earliestEventDate)) / Constants.DayTime
    }
    
}
