import Foundation
import UserNotifications
import Combine

/// Service managing device push notifications (APNs / FCM) and local alert banners.
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    @Published var isPermissionGranted: Bool = false
    @Published var apnsToken: String?
    @Published var fcmToken: String?
    @Published var recentDeliveredAlerts: [String] = []

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Requests user authorization for banner, sound, and badge notifications.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isPermissionGranted = granted
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Posts an immediate local notification when a member of a group exits a geofence.
    func postGeofenceExitAlert(
        memberName: String,
        groupName: String,
        geofenceName: String,
        isSimulated: Bool
    ) {
        let content = UNMutableNotificationContent()
        let prefix = isSimulated ? "[SIMULATION] " : "⚠️ "
        content.title = "\(prefix)Geofence Alert: \(memberName)"
        content.subtitle = "Group: \(groupName)"
        content.body = "\(memberName) has moved outside the '\(geofenceName)' geofence boundary!"
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule local notification: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.recentDeliveredAlerts.append("\(memberName) exited \(geofenceName) (\(Date().formatted()))")
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
