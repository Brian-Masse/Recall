//
//  NotificationManager.swift
//  Recall
//
//  Created by Brian Masse on 9/6/23.
//

import Foundation
import UserNotifications

class NotificationManager {
    
    static let shared = NotificationManager()
    
    static let reminderNotificationIdentifier = "reminderNotificationIdentifier"
    static let reminderTitle = "Time for your daily Recall"
    static let reminderMessage = "Take a few moments to recall the events and pace of your day today."
    
    @MainActor
    func requestNotifcationPermissions() {
        
        let options: UNAuthorizationOptions = [ .alert, .sound ]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (success, error) in
            if let error = error {
                print("error requesting notifcation permission: \(error.localizedDescription)")
            } else {
                if !success { RecallModel.index.notificationsEnabled = false }
            }
        }
    }
    
    private func makeReminderNotification() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = NotificationManager.reminderTitle
        content.body = NotificationManager.reminderMessage
        content.sound = .ringtoneSoundNamed(.init("Tri-tone"))
        return content
        
    }
    
    func makeNotificationRequest(from time: Date) {
        
        let components = Calendar.current.dateComponents([ .hour, .minute ], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let content = makeReminderNotification()
        
        let request = UNNotificationRequest(identifier: NotificationManager.reminderNotificationIdentifier,
                                            content: content,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeReminderNotification() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [NotificationManager.reminderNotificationIdentifier])
    }
    
}
