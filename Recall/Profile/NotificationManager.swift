//
//  NotificationManager.swift
//  Recall
//
//  Created by Brian Masse on 9/6/23.
//

import Foundation
import UserNotifications

class NotificationManager {
    
//    MARK: Vars
    static let shared = NotificationManager()
    
    static let reminderNotificationIdentifier = "reminderNotificationIdentifier"
    static let reminderTitle = "Time for your daily Recall"
    static let reminderMessage = "Take a few moments to recall the events and pace of your day today."
    
    static let birthdayNotificationIdentifier = "birthdayNotificationIdentifier"
    static var birthdayTitle: String { "Happy birthday \(RecallModel.index.firstName)!" }
    static let birthdayMessage = "Have a great day today :)"
    
//    MARK: Class Methods
    @MainActor
    func requestNotifcationPermissions() {
        
        let options: UNAuthorizationOptions = [ .alert, .sound ]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
            if let error = error {
                print("error requesting notifcation permission: \(error.localizedDescription)")
            } else {
                if !success {
                    DispatchQueue.main.sync {
                        RealmManager.updateObject(RecallModel.index) { thawed in
                            thawed.notificationsEnabled = false
                        }
                    }
                }
            }
        }
    }
    
    func makeNotificationRequest(from time: Date) {
        let content = makeNotificationContent(title: NotificationManager.reminderTitle,
                                              body: NotificationManager.reminderMessage)
        
        let components = Calendar.current.dateComponents([ .hour, .minute ], from: time)
        
        makeCalendarNotificationRequest(components: components,
                                        identifier: NotificationManager.reminderNotificationIdentifier,
                                        content: content)
    }
    
    func makeBirthdayNotificationRequest( from date: Date ) {
        let content = makeNotificationContent(title: NotificationManager.birthdayTitle,
                                              body: NotificationManager.birthdayMessage)
        
        let components = Calendar.current.dateComponents([ .day, .month ], from: date)
        
        makeCalendarNotificationRequest(components: components,
                                        identifier: NotificationManager.birthdayNotificationIdentifier,
                                        content: content)
        
        
    }
    
    func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [NotificationManager.reminderNotificationIdentifier,
                                                                                          NotificationManager.birthdayNotificationIdentifier
                                                                                         ])
    }
    
//    MARK: Production Methods
    private func makeNotificationContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .ringtoneSoundNamed(.init("Tri-tone"))
        return content
    }
    
    private func makeCalendarNotificationRequest(components: DateComponents, identifier: String, content: UNMutableNotificationContent ) {
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
