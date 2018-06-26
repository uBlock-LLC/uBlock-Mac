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

extension Notification.Name {
    static let killLauncher = Notification.Name("org.uBlockLLC.killLauncher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainAppIdentifier = "org.uBlockLLC.uBlock"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty
        
        if !isRunning {
            DistributedNotificationCenter.default().addObserver(self,
                                                                selector: #selector(self.terminate),
                                                                name: .killLauncher,
                                                                object: mainAppIdentifier)
            
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("uBlock") //main app name
            
            let newPath = NSString.path(withComponents: components)
            
            NSWorkspace.shared.launchApplication(newPath)
        } else {
            self.terminate()
        }
    }
    
    @objc func terminate() {
        NSApp.terminate(nil)
    }
}
