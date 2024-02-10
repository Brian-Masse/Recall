//
//  RecallModel.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI
import UIUniversals

//Main user ownerID
//64b8478c84023dfb762af304
let inDev = true

struct RecallModel {
    
//  OUTLOOK:    64e4235dadda1f970fc082ed
//  GMAIL:      64e3f9d5ac7aee58fbbceb37
    
    static var shared: RecallModel = RecallModel()
    
    static var ownerID: String {
//        "64b8478c84023dfb762af304"
        RecallModel.realmManager.user?.id ?? ""
        
//        "64ba0fbbd6e75f291b404772"
    }
    
    @MainActor
    static let realmManager: RealmManager = RealmManager()
    static var index: RecallIndex { RecallModel.realmManager.index  }
    static let updateManager: UpdateManager = UpdateManager()

    private(set) var activeColor: Color = Colors.lightAccent
    
    mutating func setActiveColor(from colorScheme: ColorScheme) {
//        activeColor = colorScheme == .dark ? Colors.darkAccent : Colors.lightAccent
    }
    
    @MainActor
    static func getDaysSinceFirstEvent() -> Double {
        (Date.now.timeIntervalSince(getEarliestEventDate() )) / Constants.DayTime
    }
    
    @MainActor
    static func getEarliestEventDate() -> Date {
        RecallModel.index.earliestEventDate
    }
    
    @MainActor
    mutating func setTint(from colorScheme: ColorScheme ) {
        activeColor = colorScheme == .dark ? Colors.darkAccent : Colors.lightAccent
    }
    
    static let dataModel: RecallDataModel = RecallDataModel()
    
    static func wait(for seconds: Double) async {
        try! await Task.sleep(nanoseconds: UInt64( seconds * pow( 10, 9 )) )
    }

}
