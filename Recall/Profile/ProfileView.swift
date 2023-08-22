//
//  ProfileView.swift
//  Recall
//
//  Created by Brian Masse on 8/21/23.
//

import Foundation
import SwiftUI

struct ProfileView: View {
    
    @State var showingDataTransfer: Bool = false
    @State var ownerID: String = ""
    
    var body: some View {
        
        VStack {
            
            Spacer()
            
            LargeRoundedButton( "Transfer Data", icon: "arrow.right" ) { showingDataTransfer = true }
            
            LargeRoundedButton("Signout", icon: "arrow.down") { RecallModel.realmManager.logoutUser() }
            
        }
        .universalBackground()
        .alert("OwnerID", isPresented: $showingDataTransfer) {
            TextField("ownerID", text: $ownerID)
            Button(role: .destructive) {
                RecallModel.realmManager.transferDataOwnership(to: ownerID)
            } label: { Text("Transfer Data") }
        }
        
    }
    
}
