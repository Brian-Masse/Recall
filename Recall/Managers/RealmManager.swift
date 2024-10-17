//
//  RealmManager.swift
//  Recall
//
//  Created by Brian Masse on 7/14/23.
//

import Foundation
import RealmSwift
import Realm
import AuthenticationServices
import SwiftUI

//RealmManager is responsible for signing/logging in users, opening a realm, and any other
//high level function.
//it functions both online and offline, but does not yet switch between them automatically
//MARK: RealmManager
class RealmManager: ObservableObject {
    
    public enum AuthenticationState: String {
        case splashScreen
        case authenticating
        case openingRealm
        case creatingProfile
        case tutorial
        case error
        case complete
    }
    
    static let appID = "application-0-incki"
    
//    This realm will be generated once the profile has authenticated themselves
    var realm: Realm!
    var app = RealmSwift.App(id: RealmManager.appID)
    var user: User?
    var configuration: Realm.Configuration!
    
    var index: RecallIndex!
    
//    These variables are just temporary storage until the realm is initialized, and can be put in the database
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    
//   if the user uses signInWithApple, this will be set to true once it successfully retrieves the credentials
//   Then the app will bypass the setup portion that asks for your first and last name
    static var usedSignInWithApple: Bool = false
    
    @Published var authenticationState: AuthenticationState = .splashScreen
    
//    MARK: Subscriptions
//    These can add, remove, and return compounded queries. During the app lifecycle, they'll need to change based on the current view
    var calendarEventQuery: (QueryPermission<RecallCalendarEvent>) {
        .init(named: QuerySubKey.calendarComponent.rawValue) { query in query.ownerID == RecallModel.ownerID }
    }
    
    var categoryQuery: (QueryPermission<RecallCategory>) {
        .init(named: QuerySubKey.category.rawValue) { query in query.ownerID == RecallModel.ownerID }
    }
    
    var goalsQuery: (QueryPermission<RecallGoal>) {
        .init(named: QuerySubKey.goal.rawValue) { query in query.ownerID == RecallModel.ownerID }
    }
    
    var goalsNodeQuery: (QueryPermission<GoalNode>) {
        .init(named: QuerySubKey.goalNode.rawValue) { query in query.ownerID == RecallModel.ownerID }
    }
    
    var indexQuery: (QueryPermission<RecallIndex>) {
        .init(named: QuerySubKey.index.rawValue) { query in query.ownerID == RecallModel.ownerID }
    }
    
    var dicQuery: (QueryPermission<DictionaryNode>) {
        .init(named: QuerySubKey.dictionary.rawValue) { query in query.ownerID == RecallModel.ownerID }
    }
    
    var summaryQuery: (QueryPermission<RecallDailySummary>) {
        .init(named: QuerySubKey.summary.rawValue) { query in query.ownerID == RecallModel.ownerID }
    }
    
//    MARK: Initialization
    init() {
        Task { await self.checkLogin() }
    }
    
    @MainActor
    func setState( _ newState: AuthenticationState ) {
        let newState: AuthenticationState = newState == .tutorial && self.index.finishedTutorial ? .complete : newState
        withAnimation { self.authenticationState = newState }
    }
    
    static func stripEmail(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
//    MARK: SignInWithAppple
//    most of the authenitcation / registration is handled by Apple
//    All I need to do is check that nothing went wrong, and then move the signIn process along
    func signInWithApple(_ authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            print("successfully retrieved credentials")
            self.email = credential.email ?? ""
            self.firstName = credential.fullName?.givenName ?? ""
            self.lastName = credential.fullName?.familyName ?? ""
            
            if let token = credential.identityToken {
                let idTokenString = String(data: token, encoding: .utf8)
                let realmCredentials = Credentials.apple(idToken: idTokenString!)
                
                RealmManager.usedSignInWithApple = true
                Task { await RecallModel.realmManager.authOnineUser(credentials: realmCredentials ) }
                
            } else {
                print("unable to retrieve idenitty token")
            }
            
        default:
            print("unable to retrieve credentials")
            break
        }
    }
    
//    MARK: SignInWithPassword
//    the basic flow, for offline and online, is to
//    1. check the email + password are valid (reigsterUser)
//    2. authenticate the user (save their information into defaults or Realm)
//    3. postAuthenticatinInit (move onto opening the realm)
    func signInWithPassword(email: String, password: String) async -> String? {
        
        let fixedEmail = RealmManager.stripEmail(email)
        
        let error =  await registerOnlineUser(fixedEmail, password)
        if error == nil {
            let credentials = Credentials.emailPassword(email: fixedEmail, password: password)
            self.email = fixedEmail
            let secondaryError = await authOnineUser(credentials: credentials)
            
            if secondaryError != nil {
                print("error authenticating registered user")
                return secondaryError!.localizedDescription
            }
        }
        return error?.localizedDescription ?? nil
    }
    
//    only needs to run for email + password signup
//    checks whether the provided email + password is valid
    private func registerOnlineUser(_ email: String, _ password: String) async -> Error? {
        
        let client = app.emailPasswordAuth
        do {
            try await client.registerUser(email: email, password: password)
            return nil
        } catch {
            if error.localizedDescription == "name already in use" { return nil }
            print("failed to register user: \(error.localizedDescription)")
            return error
        }
    }
    
//        this simply logs the profile in and returns any status errors
//        Once done, it moves the app onto the loadingRealm phase
    func authOnineUser(credentials: Credentials) async -> Error? {
        do {
            self.user = try await app.login(credentials: credentials)
            await self.postAuthenticationInit()
            return nil
        } catch { print("error logging in: \(error.localizedDescription)"); return error }
    }
    
//    MARK: Login / Authentication Functions
//    If there is a user already signed in, skip the user authentication system
//    the method for checking if a user is signedIn is different whether you're online or offline
    @MainActor
    func checkLogin() {
        if let user = app.currentUser {
            self.user = user
            self.postAuthenticationInit()
        }
    }
    
    @MainActor
    private func postAuthenticationInit() {
        self.setConfiguration()
        self.setState(.openingRealm)
    }
    
//    MARK: Logout
    @MainActor
    func logoutUser() {
        if let user = self.user {
            user.logOut { error in
                if let err = error { print("error logging out: \(err.localizedDescription)") }
                
                DispatchQueue.main.async {
                    NotificationManager.shared.clearNotifications()
                    self.setState(.authenticating)
                }
            }
        }
        Task { await self.removeAllNonBaseSubscriptions() }
        
        self.user = nil
    }
    
//    MARK: SetConfiguration
    private func addInitialSubscription<T: Object>(_ query: QueryPermission<T>, to subs: SyncSubscriptionSet ) {
        let subscription = query.getSubscription()
        
        if subs.first(named: query.name) == nil {
            subs.append(subscription)
        }
    }
    
    @MainActor
    private func setConfiguration() {
        self.configuration = user!.flexibleSyncConfiguration(initialSubscriptions: { subs in
            
            self.addInitialSubscription(self.calendarEventQuery, to: subs)
            self.addInitialSubscription(self.categoryQuery, to: subs)
            self.addInitialSubscription(self.goalsQuery, to: subs)
            self.addInitialSubscription(self.indexQuery, to: subs)
            self.addInitialSubscription(self.goalsNodeQuery, to: subs)
            self.addInitialSubscription(self.dicQuery, to: subs)
            self.addInitialSubscription(self.summaryQuery, to: subs)
            
        })
        
        self.configuration.objectTypes = [ RecallCalendarEvent.self,
                                           RecallCategory.self,
                                           RecallGoal.self,
                                           RecallIndex.self,
                                           GoalNode.self,
                                           DictionaryNode.self,
                                           RecallRecentUpdate.self,
                                           RecallDailySummary.self
        ]
    }
    
    
//    MARK: Profile Functions
    @MainActor
    func deleteProfile() async { self.logoutUser() }
    
//    This checks the user has created a profile with Recall already
//    if not it will trigger the ProfileCreationScene
    @MainActor
    func checkProfile() async {
        let results: Results<RecallIndex> = RealmManager.retrieveObject()
        
        if let index = results.first(where: { index in index.ownerID == RecallModel.ownerID }) {
            self.index = index
            self.index.toggleNotifcations(to: index.notificationsEnabled, time: index.notificationsTime)
            self.setState(.tutorial)
            
        } else {
            createIndex()
        }
    }
    
//    If the user does not have an index, create one and add it to the database
    @MainActor
    private func createIndex() {
        let index = RecallIndex()
        index.ownerID = RecallModel.ownerID
        index.dateJoined = .now
        index.email = self.email
        
        RealmManager.addObject(index)
        
        self.index = index
        self.setState(.creatingProfile)
    }

//    MARK: Realm Loading Functions
//    Called once the realm is loaded in OpenSyncedRealmView
    @MainActor
    func authRealm(realm: Realm) async {
        self.realm = realm
        await RecallModel.updateManager.initialize()
        await self.checkProfile()
        RecallModel.index.updateAccentColor()
    }
    
//    MARK: Subscription Functions
//    Subscriptions are only used when the app is online
//    otherwise you are able to retrieve all the data from the Realm by default
    func removeSubscription(name: String) async {
        let subscriptions = self.realm.subscriptions
        let foundSubscriptions = subscriptions.first(named: name)
        if foundSubscriptions == nil {return}
        
        do {
            try await subscriptions.update{
                subscriptions.remove(named: name)
            }
        } catch { print("error adding subcription: \(error)") }
    }
    
    private func checkSubscription(name: String, realm: Realm) -> Bool {
        let subscriptions = realm.subscriptions
        let foundSubscriptions = subscriptions.first(named: name)
        return foundSubscriptions != nil
    }
    
    @MainActor
    func clearAllSubscriptions() async throws {
        if let realm = self.realm {
            
            let subscriptions = realm.subscriptions
            try await subscriptions.update {
                subscriptions.removeAll(ofType: RecallCalendarEvent.self)
                
            }
        }
    }
    
    func removeAllNonBaseSubscriptions() async {
        
        if let realm = self.realm {
            if realm.subscriptions.count > 0 {
                for subscription in realm.subscriptions {
//                    if !QuerySubKey.allCases.contains(where: { key in
//                        key.rawValue == subscription.name
//                    }) {
                        await self.removeSubscription(name: subscription.name!)
//                    }
                }
            }
        }
    }
    
    @MainActor
    func transferDataOwnership(to ownerID: String) {
        
        if ownerID.isEmpty { return }
        
        let goals: [RecallGoal] = RealmManager.retrieveObjects()
        for goal in goals { RealmManager.transferOwnership(of: goal, to: ownerID) }
        
        let events: [RecallCalendarEvent] = RealmManager.retrieveObjects()
        for event in events { RealmManager.transferOwnership(of: event, to: ownerID) }
        
        let tags: [RecallCategory] = RealmManager.retrieveObjects()
        for tag in tags { RealmManager.transferOwnership(of: tag, to: ownerID) }
        
        let dataNodes: [GoalNode] = RealmManager.retrieveObjects()
        for node in dataNodes { RealmManager.transferOwnership(of: node, to: ownerID) }
        
    }
    
//    MARK: Realm Functions
    
    @MainActor
    static func transferOwnership<T: Object>(of object: T, to newID: String) where T: OwnedRealmObject {
        updateObject(object) { thawed in
            thawed.ownerID = newID
        }
    }
    
//    in all add, update, and delete transactions, the user has the option to pass in a realm
//    if they want to write to a different realm.
//    This is a convenience function either choose that realm, if it has a value, or the default realm
    static func getRealm(from realm: Realm?) -> Realm {
        realm ?? RecallModel.realmManager.realm
    }
    
    static func writeToRealm(_ realm: Realm? = nil, _ block: () -> Void ) {
        do {
            if getRealm(from: realm).isInWriteTransaction { block() }
            else { try getRealm(from: realm).write(block) }
            
        } catch { print("ERROR WRITING TO REALM:" + error.localizedDescription) }
    }
    
    static func updateObject<T: Object>(realm: Realm? = nil, _ object: T, _ block: (T) -> Void, needsThawing: Bool = true) {

        RealmManager.writeToRealm(realm) {
            guard let thawed = object.thaw() else {
                print("failed to thaw object: \(object)")
                return
            }
            
            block(thawed)
        }
    }
    
    static func addObject<T:Object>( _ object: T, realm: Realm? = nil ) {
        self.writeToRealm(realm) {
            getRealm(from: realm).add(object) }
    }
    
    static func retrieveObject<T:Object>( realm: Realm? = nil, where query: ( (Query<T>) -> Query<Bool> )? = nil ) -> Results<T> {
        if query == nil { return getRealm(from: realm).objects(T.self) }
        else { return getRealm(from: realm).objects(T.self).where(query!) }
    }
    
    @MainActor
    static func retrieveObjects<T: Object>(realm: Realm? = nil, where query: ( (T) -> Bool )? = nil) -> [T] {
        if query == nil { return Array(getRealm(from: realm).objects(T.self)) }
        else { return Array(getRealm(from: realm).objects(T.self).filter(query!)  ) }
    }

    static func deleteObject<T: RealmSwiftObject>( _ object: T, where query: @escaping (T) -> Bool, realm: Realm? = nil ) where T: Identifiable {
        
        if let obj = getRealm(from: realm).objects(T.self).filter( query ).first {
            self.writeToRealm {
                getRealm(from: realm).delete(obj)
            }
        }
    }
}

protocol OwnedRealmObject: Object {
    var ownerID: String { get set }
}
