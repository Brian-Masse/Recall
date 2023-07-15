//
//  RecallModel.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import SwiftUI

@MainActor
struct RecallModel {
    
    static let shared: RecallModel = RecallModel()
    static let realmManager: RealmManager = RealmManager()
    
    static var ownerID: String { RecallModel.realmManager.user?.id ?? "" }
    
    let activeColor: Color = Colors.main
    
}
