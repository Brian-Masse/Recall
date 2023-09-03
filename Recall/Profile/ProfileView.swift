//
//  ProfileView.swift
//  Recall
//
//  Created by Brian Masse on 8/21/23.
//

import Foundation
import SwiftUI

@MainActor
struct ProfileView: View {
    
//    MARK: Vars
    
    @State var showingDataTransfer: Bool = false
    @State var showingEditingView: Bool = false
    @State var ownerID: String = ""
    
    @Binding var appPage: ContentView.EntryPage
    
    let index = RecallModel.index
    
//    MARK: ViewBuilders
    
    @ViewBuilder
    private func makeSubButton( title: String, icon: String, action: @escaping () -> Void ) -> some View {
        HStack {
            Spacer()
            UniversalText( title, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
            Image(systemName: icon)
            Spacer()
        }
        .secondaryOpaqueRectangularBackground()
        .onTapGesture { action() }
    }
    
    @ViewBuilder
    private func makeContactLabel( title: String, content: String ) -> some View {
        HStack {
            UniversalText(title, size: Constants.UIDefaultTextSize, font: Constants.titleFont )
            Spacer()
            UniversalText(content, size: Constants.UIDefaultTextSize, font: Constants.mainFont )
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
    }
    
    @ViewBuilder
    private func makeDemographicLabel(mainText: String, secondaryText: String, tertiaryText: String) -> some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    UniversalText( mainText, size: Constants.UIHeaderTextSize, font: Constants.titleFont )
                    UniversalText( secondaryText, size: Constants.UIDefaultTextSize, font: Constants.mainFont, wrap: false, scale: true )
                }
                Spacer()
            }
            .secondaryOpaqueRectangularBackground()
            
            UniversalText( tertiaryText, size: Constants.UISmallTextSize, font: Constants.mainFont )
        }
    }
    
    @ViewBuilder
    private func makeDemographicInfo() -> some View {
        
        let dayFormatted: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd"
            return formatter
        }()
        
        let yearFormatted: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM, yyyy"
            return formatter
        }()
        
        
        UniversalText( "Overview", size: Constants.UIHeaderTextSize, font: Constants.titleFont )
        VStack(alignment: .leading) {
            HStack {
                makeDemographicLabel(mainText: dayFormatted.string(from: index.dateJoined),
                                     secondaryText: yearFormatted.string(from: index.dateJoined),
                                     tertiaryText: "Date Joined")
                
                makeDemographicLabel(mainText: dayFormatted.string(from: index.dateOfBirth),
                                     secondaryText: yearFormatted.string(from: index.dateOfBirth),
                                     tertiaryText: "Date of Birth")
            }.padding(.bottom)
            
            UniversalText( "Contact Information", size: Constants.UISubHeaderTextSize, font: Constants.titleFont )
                .padding(.bottom, 5 )
            makeContactLabel(title: "email", content: index.email)
            makeContactLabel(title: "phone number", content: "\(index.phoneNumber.formatIntoPhoneNumber())")
        }
        .opaqueRectangularBackground(7, stroke: true)
        .padding(.bottom, 5)
        
        makeSubButton(title: "Replay Tutorial", icon: "arrow.clockwise") {
            index.replayTutorial()
            appPage = .login
        }
        
        makeSubButton(title: "reindex Data", icon: "tray.2") {
            Task {
                await RecallModel.index.initializeIndex()
            }
        }
    }
    
    @ViewBuilder
    private func makePageHeader() -> some View {
        UniversalText(index.getFullName(), size: Constants.UITitleTextSize, font: Constants.titleFont)
        UniversalText( RecallModel.ownerID, size: Constants.UISmallTextSize, font: Constants.mainFont )
    }
    
    @ViewBuilder
    private func makePageFooter() -> some View {
        VStack {
            LargeRoundedButton( "Edit", icon: "arrow.right", wide: true ) { showingEditingView = true }
//            LargeRoundedButton( "Transfer Data", icon: "arrow.right", wide: true ) { showingDataTransfer = true }
            LargeRoundedButton("Signout", icon: "arrow.down", wide: true) {
                RecallModel.realmManager.logoutUser()
                appPage = .splashScreen
            }
        }
    }
    
//    MARK: Body
    var body: some View {
        
        VStack(alignment: .leading) {
                
            makePageHeader()
                .padding(.bottom)
            
            makeDemographicInfo()
            
            Spacer()
            
            makePageFooter()
                .padding(.bottom, 20)
            
        }
        .padding(7)
        .universalBackground()
        .alert("OwnerID", isPresented: $showingDataTransfer) {
            TextField("ownerID", text: $ownerID)
            Button(role: .destructive) {
                RecallModel.realmManager.transferDataOwnership(to: ownerID)
            } label: { Text("Transfer Data") }
        }
        .sheet(isPresented: $showingEditingView) {
            ProfileEditorView(email: index.email,
                              phoneNumber: index.phoneNumber,
                              dateOfBirth: index.dateOfBirth,
                              firstName: index.firstName,
                              lastName: index.lastName)
        }
        
    }
    
}
