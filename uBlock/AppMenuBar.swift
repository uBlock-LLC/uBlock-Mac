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

import Foundation
import Cocoa
import ServiceManagement
import SwiftyBeaver

class AppMenuBar: NSObject {
    
    static let ADS_CLICKED = 1
    static let ALLOW_ADS_CLICKED = 2
    static var lastFilterListMenuOperation: Int = 0
    
    var statusItem: NSStatusItem?
    
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var adsMenuItem: NSMenuItem!
    @IBOutlet weak var allowAdsMenuItem: NSMenuItem!
    @IBOutlet weak var startAppAtLoginMenuItem: NSMenuItem!
    
    override init() {
        super.init()        
    }
    
    func initializeAppMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(named:NSImage.Name("MenuBarAppIcon-16pt"))
        }
        statusItem?.menu = menu
    }
    
    fileprivate func updateFilterListsItemsState() {
        if FilterListManager.shared.isEnabled(filterListId: Constants.ADS_FILTER_LIST_ID) {
            adsMenuItem.state = .on
            allowAdsMenuItem.isEnabled = true
        } else {
            adsMenuItem.state = .off
            allowAdsMenuItem.isEnabled = false
        }
        
        if FilterListManager.shared.isEnabled(filterListId: Constants.ALLOW_ADS_FILTER_LIST_ID) {
            allowAdsMenuItem.state = .on
        } else {
            allowAdsMenuItem.state = .off
        }
    }
    
    fileprivate func activateApp() {
        NSWorkspace.shared.launchApplication("uBlock")
    }
    
    @IBAction func adsMenuItemClick(_ sender: NSMenuItem) {
        AppMenuBar.lastFilterListMenuOperation = AppMenuBar.ADS_CLICKED
        if sender.state == .on {
            FilterListManager.shared.disable(filterListId: Constants.ADS_FILTER_LIST_ID)
            FilterListManager.shared.disable(filterListId: Constants.ALLOW_ADS_FILTER_LIST_ID)
        } else {
            FilterListManager.shared.enable(filterListId: Constants.ADS_FILTER_LIST_ID)
        }
        updateFilterListsItemsState()
        FilterListManager.shared.callAssetMerge()
    }
    
    @IBAction func allowAdsMenuItemClick(_ sender: NSMenuItem) {
        AppMenuBar.lastFilterListMenuOperation = AppMenuBar.ALLOW_ADS_CLICKED
        if sender.state == .on {
            FilterListManager.shared.disable(filterListId: Constants.ALLOW_ADS_FILTER_LIST_ID)
        } else {
            FilterListManager.shared.enable(filterListId: Constants.ALLOW_ADS_FILTER_LIST_ID)
        }
        updateFilterListsItemsState()
        FilterListManager.shared.callAssetMerge()
    }
    
    @IBAction func whitelistMenuItemClick(_ sender: NSMenuItem) {
        activateApp()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            Constants.shouldSelectWhitelist.set(newValue: true)
        }
    }
    
    @IBAction func updateFilterListsMenuItemClick(_ sender: NSMenuItem) {
        activateApp()
        AssetsManager.shared.requestFilterUpdate()
        AlertUtil.displayNotification(title: NSLocalizedString("Filter Lists", comment: ""),
                                      message: NSLocalizedString("Updating the filter lists...", comment: ""))
    }
    
    @IBAction func startAppOnLoginClick(_ sender: NSMenuItem) {
        let launcherAppId = "org.uBlockLLC.LauncherApp"
        let launchApp = sender.state == .on ? false : true
        if !SMLoginItemSetEnabled(launcherAppId as CFString, launchApp) {
            SwiftyBeaver.error("Error in setting launcher app")
        } else {
            sender.state = sender.state == .on ? .off : .on
            UserPref.setLaunchAppOnUserLogin(launchApp)
        }
    }
    
    @IBAction func aboutMenuItemClick(_ sender: Any) {
        activateApp()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            NSApp.orderFrontStandardAboutPanel(self)
        }
    }
}

extension AppMenuBar : NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateFilterListsItemsState()
        startAppAtLoginMenuItem.state = UserPref.isLaunchAppOnUserLogin() ? .on : .off
    }
}
