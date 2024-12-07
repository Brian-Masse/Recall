//
//  RecallIcon.swift
//  Recall
//
//  Created by Brian Masse on 12/14/24.
//

import Foundation
import UIUniversals
import SwiftUI

struct RecallIcon: View {
    
    let icon: String
    let bold: Bool
    
    init(_ icon: String, bold: Bool = true) {
        self.icon = icon
        self.bold = bold
    }
    
    var body: some View {
        Image(systemName: icon)
            .bold(bold)
    }
}

