import Cocoa
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var notificationTitle = "Claude Code"
    var notificationMessage = "Claude needs your attention"
    var notificationSound: String?
    var onClick: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)

        parseArgs()

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if !granted {
                fputs("Notification permission denied. Enable in System Settings > Notifications > claude-notify.\n", stderr)
                NSApp.terminate(nil)
                return
            }
            self.postNotification(center: center)
        }
    }

    func parseArgs() {
        var args = Array(CommandLine.arguments.dropFirst())
        var i = 0
        while i < args.count {
            switch args[i] {
            case "--title":
                i += 1; if i < args.count { notificationTitle = args[i] }
            case "--message":
                i += 1; if i < args.count { notificationMessage = args[i] }
            case "--sound":
                i += 1; if i < args.count { notificationSound = args[i] }
            case "--on-click":
                i += 1; if i < args.count { onClick = args[i] }
            default: break
            }
            i += 1
        }
    }

    func postNotification(center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.body = notificationMessage
        if let soundName = notificationSound {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                fputs("Failed to post notification: \(error.localizedDescription)\n", stderr)
                NSApp.terminate(nil)
                return
            }
            if self.onClick == nil {
                // No click handler, exit after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NSApp.terminate(nil)
                }
            }
            // Otherwise stay alive to handle click
        }
    }

    // Show banner even if app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // Handle notification click
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let cmd = onClick, response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", cmd]
            try? task.run()
            task.waitUntilExit()
        }
        completionHandler()
        NSApp.terminate(nil)
    }

    // Timeout — don't hang forever
    func scheduleTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
delegate.scheduleTimeout()
app.run()
