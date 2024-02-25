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

//this handles logging in, and opening the right realm with the right credentials
class RealmManager: ObservableObject {
        
//    if the app is being used offline, then the 'user' will be stored in defaults
    static let defaults = UserDefaults.standard
    
    static let offline: Bool = true
    static let appID = "application-0-incki"
    
//    This realm will be generated once the profile has authenticated themselves (handled in LoginModel)
//    and the AsyncOpen call in LoginView has completed
    var realm: Realm!
    var app = RealmSwift.App(id: RealmManager.appID)
    var configuration: Realm.Configuration!
    
    var index: RecallIndex!

//    This is the realm profile that signed into the app
//    when offline, there will be no user (user is a construct used for device sync)
//    instead a key, email, and password will be saved into defaults, and that will be used as a 'user'
//    the most important is the key, which will coorespond to the user id and access data
    var user: User?
    var offlineUser: OfflineUser?
    
//    These variables are just temporary storage until the realm is initialized, and can be put in the database
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    
//   if the user uses signInWithApple, this will be set to true once it successfully retrieves the credentials
//   Then the app will bypass the setup portion that asks for your first and last name
    static var usedSignInWithApple: Bool = false
    
    @Published var signedIn: Bool = false
    @Published var realmLoaded: Bool = false
    @Published var hasProfile: Bool = false
    
    var profileLoaded: Bool {
        if hasProfile {
            return self.index.checkCompletion()
        } else {
            return false
        }
    }
    
//    These can add, remove, and return compounded queries. During the app lifecycle, they'll need to change based on the current view
    lazy var calendarEventQuery: (QueryPermission<RecallCalendarEvent>) = QueryPermission { query in query.ownerID == RecallModel.ownerID
        
    }
    @MainActor lazy var categoryQuery: (QueryPermission<RecallCategory>)           = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    @MainActor lazy var goalsQuery: (QueryPermission<RecallGoal>)                  = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    @MainActor lazy var goalsNodeQuery: (QueryPermission<GoalNode>)                = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    @MainActor lazy var indexQuery: (QueryPermission<RecallIndex>)                 = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    @MainActor lazy var dicQuery: (QueryPermission<DictionaryNode>)                = QueryPermission { query in query.ownerID == RecallModel.ownerID }
    
    
    @MainActor
    init() {
        RealmManager.getOfflineUsers()
        self.checkLogin()
    }
    
//    MARK: Login Method Functions
//    I need to handle the case where you dont get an email, but im not sure that literally ever happens
//    so I think Im all set
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
    
    static func stripEmail(_ email: String) -> String {
        email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
//    the basic flow, for offline and online, is to
//    1. check the email + password are valid (reigsterUser)
//    2. authenticate the user (save their information into defaults or Realm)
//    3. postAuthenticatinInit (move onto opening the realm)
    func signInWithPassword(email: String, password: String) async -> String? {
        
        let fixedEmail = RealmManager.stripEmail(email)
        
        if RealmManager.offline {
            let error = await registerOfflineUser(fixedEmail, password)
            if error != nil { return error }
            
            await authOfflineUser(fixedEmail, password: password)
        }
        
        if !RealmManager.offline {
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
        return ""
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
    
    @MainActor
    private func registerOfflineUser(_ email: String, _ password: String) -> String? {
        if let user = RealmManager.offlineUsers.first(where: { user in
            user.email == email
        }) {
//            nil if you're logging into an existing account - no error
//            error if the email exists but the passwords dont match
            if user.password == password { return nil }
            else { return "failed to register user: inocrrect password" }
        }
        
        return nil
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
    
    @MainActor
    func authOfflineUser( _ email: String, password: String ) {
        var id: String = UUID().uuidString
        
        if let user = RealmManager.offlineUsers.first(where: { user in
            user.email == email
        }) {
            id = user.id
        }
        
        let user = OfflineUser(email: email, password: password, id: id)
        user.signedIn = true
        
        self.offlineUser = user
        
        RealmManager.writeToDefaults(user, at: id)
        
        postAuthenticationInit()
    }
    
    
//    MARK: Authentication Functions
//    If there is a user already signed in, skip the user authentication system
    @MainActor
    func checkLogin() {
        if RealmManager.offline {
            if let user = RealmManager.offlineUsers.first(where: { user in user.signedIn }) {
                self.offlineUser = user
                self.postAuthenticationInit()
            }
        } else {
            if let user = app.currentUser {
                self.user = user
                self.postAuthenticationInit()
            }
        }
    }
    
    @MainActor
    private func postAuthenticationInit() {
        self.setConfiguration()
        withAnimation {
            self.signedIn = true
        }
    }
    
    private func setConfiguration() {
        if !RealmManager.offline {
            self.configuration = user!.flexibleSyncConfiguration(clientResetMode: .discardUnsyncedChanges())
            
            Realm.Configuration.defaultConfiguration = self.configuration
        } else {
            self.configuration = Realm.Configuration.defaultConfiguration
        }
    }
    
//    MARK: Logout
    @MainActor
    func logoutUser(onMain: Bool = false) {
        if RealmManager.offline {
            if let offlineUser = self.offlineUser {
                
                let newUser = offlineUser
                newUser.signedIn = false
                
                RealmManager.writeToDefaults(newUser, at: newUser.id)
                NotificationManager.shared.clearNotifications()
                
                self.signedIn = false
                self.hasProfile = false
                self.realmLoaded = false
            }
            
        } else {
            if let user = self.user {
                user.logOut { error in
                    if let error = error { print("error logging out: \(error.localizedDescription)") }
                    
                    NotificationManager.shared.clearNotifications()
                    
                    if !onMain {
                        DispatchQueue.main.sync {
                            self.signedIn = false
                            self.hasProfile = false
                            self.realmLoaded = false
                        }
                    } else {
                        self.signedIn = false
                        self.hasProfile = false
                        self.realmLoaded = false
                    }
                }
            }
            Task {
                do { try await self.clearAllSubscriptions() } catch {
                    print("error clearing subscriptions: \(error.localizedDescription)")
                }
            }
        }
        
        self.user = nil
        self.offlineUser = nil
    }
    
//    MARK: Profile Functions
    
    @MainActor
    func deleteProfile() async {
        self.logoutUser(onMain: true)
    }
    
    @MainActor
    func checkProfile() async {
//        RealmManager already has a query subscription to access the index
        
        let results: Results<RecallIndex> = RealmManager.retrieveObject()
        
        if let index = results.first(where: { index in
            index.ownerID == RecallModel.ownerID
        }) {
            registerIndexLocally(index)
            index.toggleNotifcations(to: index.notificationsEnabled, time: index.notificationsTime)
        } else {
            createIndex()
        }

        
    }
    
//    If the user does not have an index, create one and add it to the database
    private func createIndex() {
        let index = RecallIndex()
        index.ownerID = RecallModel.ownerID
        index.dateJoined = .now
        index.email = self.email
        
        RealmManager.addObject(index)
        
        registerIndexLocally(index)
    }
    
//    whether you're loading the profile from the databae or creating at startup, it should go throught this function to
//    let the model know that the profile now has a profile and send that profile object to the model
    private func registerIndexLocally( _ index: RecallIndex ) {
        hasProfile = true
        self.index = index
    }

//    MARK: Realm-Loaded Functions
    @MainActor
//    this is for offline app
    func openNonSyncedRealm() async {
        do {
            let realm = try await Realm()
            self.realm = realm
        } catch {
            print("error opening local realm: \(error.localizedDescription)")
        }
        
//        await self.addSubcriptions()
        self.realmLoaded = true
        await self.checkProfile()
    }
    
    
//    Called once the realm is loaded in OpenSyncedRealmView
    @MainActor
    func authRealm(realm: Realm) async {
        self.realm = realm
        await self.addSubcriptions()
        await RecallModel.updateManager.initialize()
        
        self.realmLoaded = true
        await self.checkProfile()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    
    private func addSubcriptions() async {
//            This is a clunky way of doing this
//            Effectivley, the order is login -> authenticate user (setup dud realm configuration) -> create synced realm (with responsive UI)
//             ->add the subscriptions (which downloads the data from the cloud) -> enter into the app with proper config and realm
//            Instead, when creating the configuration, use initalSubscriptions to provide the subs before creating the relam
//            This wasn't working before, but possibly if there is an instance of Realm in existence it might work?
        
        await self.removeAllNonBaseSubscriptions()
        
        let _:RecallCalendarEvent?  = await self.addGenericSubcriptions(name: QuerySubKey.calendarComponent.rawValue, query: calendarEventQuery.baseQuery )
        let _:RecallCategory?       = await self.addGenericSubcriptions(name: QuerySubKey.category.rawValue, query: categoryQuery.baseQuery )
        let _:RecallGoal?           = await self.addGenericSubcriptions(name: QuerySubKey.goal.rawValue, query: goalsQuery.baseQuery )
        let _:GoalNode?             = await self.addGenericSubcriptions(name: QuerySubKey.goalNode.rawValue, query: goalsNodeQuery.baseQuery )
        let _:RecallIndex?          = await self.addGenericSubcriptions(name: QuerySubKey.index.rawValue, query: indexQuery.baseQuery )
        let _:DictionaryNode?       = await self.addGenericSubcriptions(name: QuerySubKey.dictionary.rawValue, query: dicQuery.baseQuery )

    }
    
//    MARK: Helper Functions
    func addGenericSubcriptions<T>(realm: Realm? = nil, name: String, query: @escaping ((Query<T>) -> Query<Bool>) ) async -> T? where T:RealmSwiftObject  {
            
        let localRealm = (realm == nil) ? self.realm! : realm!
        let subscriptions = localRealm.subscriptions
        
        do {
            try await subscriptions.update {
                
                let querySub = QuerySubscription(name: name, query: query)
                
                if checkSubscription(name: name, realm: localRealm) {
                    let foundSubscriptions = subscriptions.first(named: name)!
                    foundSubscriptions.updateQuery(toType: T.self, where: query)
                }
                else { subscriptions.append(querySub) }
            }
        } catch { print("error adding subcription: \(error)") }
        
        return nil
    }
    
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
        self.writeToRealm(realm) { getRealm(from: realm).add(object) }
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
    
//    MARK: Defaults Functions
    
    class OfflineUser: Codable {
        let email: String
        let password: String
        let id: String
        var signedIn: Bool = false
     
        init(email: String, password: String, id: String) {
            self.email = email
            self.password = password
            self.id = id
        }
    }
    
//    this is a temporary 'database' that stores all the users who have signed in offline on a device
//    OfflineUsers are encoded into UserDefaults, whcich might be expensive to retrieve many times,
//    so when RealmManager initializes, it decodes all of them and stores them in this list to access
    static var offlineUsers: [OfflineUser] = []
    
    static func getOfflineUsers() {
        let users = RealmManager.defaults.dictionaryRepresentation().compactMap { node in
            if let user = RealmManager.readFromDefaults(at: node.key) {
                return user
            }
            return nil
        }
        RealmManager.offlineUsers = users
    }
    
    static func clearUserDefaults() {
        for user in RealmManager.offlineUsers {
            if user.id != RecallModel.ownerID {
                RealmManager.defaults.removeObject(forKey: user.id)
            }
        }
        RealmManager.getOfflineUsers()
    }
    
    static func writeToDefaults( _ user: OfflineUser, at key: String ) {
        if let encoded = try? JSONEncoder().encode(user) {
            RealmManager.defaults.set(encoded, forKey: key)
        }
        RealmManager.getOfflineUsers()
    }
    
    static func readFromDefaults( at key: String ) -> OfflineUser? {
        if let data = RealmManager.defaults.object(forKey: key) as? Data {
            if let user = try? JSONDecoder().decode(OfflineUser.self, from: data){
                return user
            }
        }
        return nil
    }
}

protocol OwnedRealmObject: Object {
    var ownerID: String { get set }
}
