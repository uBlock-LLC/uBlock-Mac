/*******************************************************************************
 
 µBlock - the most powerful, FREE ad blocker.
 Copyright (C) 2018 The µBlock authors
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see {http://www.gnu.org/licenses/}.
 
 Home: https://github.com/uBlock-LLC/uBlock-Mac
 */

import Cocoa
import Fabric
import Crashlytics
import SwiftyBeaver
import ServiceManagement
import SafariServices

extension Notification.Name {
    static let killLauncher = Notification.Name("org.uBlockLLC.killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindow: NSWindow?
    @IBOutlet weak var appMenuBar: AppMenuBar!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Ref: https://docs.fabric.io/apple/crashlytics/os-x.html
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])
        
        if (Constants.DEBUG_LOG_ENABLED) {
            SwiftyBeaver.addDestination(ConsoleDestination())
        }
        
        AssetsManager.shared.initialize()
        FilterListManager.shared.initialize()
        killLauncherIfRunning()
        IAPManager.shared.initialize()
    }

    private func killLauncherIfRunning() {
        let launcherAppId = "org.uBlockLLC.LauncherApp"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher,
                                                         object: Bundle.main.bundleIdentifier!)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            mainWindow?.makeKeyAndOrderFront(self)
        }
        return true
    }
    
    @IBAction func helpMenuClick(_ sender: Any) {
        if !NSWorkspace.shared.openFile(Constants.HELP_PAGE_URL, withApplication: "Safari") {
            guard let url = URL(string: Constants.HELP_PAGE_URL) else { return }
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func restorePurchaseMenuClick(_ sender: Any) {
        IAPManager.shared.restorePurchases { (error, restoredPurchases) in
            if error != nil {
                AlertUtil.errorAlert(title: NSLocalizedString("Error", comment: ""),
                                     message: NSLocalizedString("Unknown error occurred. Please contact support", comment: ""))
                return
            }
            
            let msg:String = {
                if restoredPurchases?.count ?? 0 > 0 {
                    return NSLocalizedString("All purchases have been restored", comment: "")
                } else {
                    return NSLocalizedString("No previous purchases were found", comment: "")
                }
            }()
            AlertUtil.infoAlert(title: NSLocalizedString("Restore Purchase", comment: ""), message: msg)
        }
    }
}

