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

struct UserPref {
    private init() {}
    
    private static func writePreferenceValue(withOperation operation: (_ pref: inout [String: Any]?)->Void) {
        var pref: [String: Any]? = FileManager.default.readJsonFile(at: Constants.AssetsUrls.userPreferenceUrl) ?? [:]
        operation(&pref)
        FileManager.default.writeJsonFile(at: Constants.AssetsUrls.userPreferenceUrl, with: pref)
    }
    
    private static func readPreferenceValue<T>(of key: String) -> T? {
        guard let pref: [String: Any]? = FileManager.default.readJsonFile(at: Constants.AssetsUrls.userPreferenceUrl) else {
            let initialPreference: [String: Any]? = ["__dummy_pref__": "__uBlock__"]
            FileManager.default.writeJsonFile(at: Constants.AssetsUrls.userPreferenceUrl, with: initialPreference)
            return nil
        }
        
        return pref?[key] as? T
    }
    
    // Removed due to app rejection by Apple to use the in-app purchase
    static func isDonationPageShown() -> Bool {
        return readPreferenceValue(of: "DONATION_PAGE_OPENED") ?? false
    }
    
    static func setDonationPageShown(_ opened: Bool) {
        writePreferenceValue { (pref) in
            pref?["DONATION_PAGE_OPENED"] = opened
        }
    }
    
    static func isIntroScreenShown() -> Bool {
        return readPreferenceValue(of: "IS_INTRO_SCREEN_SHOWN") ?? false
    }
    
    static func setIntroScreenShown(_ introShown: Bool) {
        writePreferenceValue { (pref) in
            pref?["IS_INTRO_SCREEN_SHOWN"] = introShown
        }
    }
    
    static func setFilterListsUpdatedDate(_ date: Date) {
        writePreferenceValue { (pref) in
            pref?["LAST_UPDATED_DATE"] = Int(date.timeIntervalSince1970.rounded())
        }
    }
    
    static func filterListsUpdatedDate() -> Date {
        let seconds:Int = readPreferenceValue(of: "LAST_UPDATED_DATE") ?? Int(Date().timeIntervalSince1970.rounded())
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }
    
    static func setBundledAssetsDefaultStateUpdated(_ stateUpdated: Bool) {
        writePreferenceValue { (pref) in
            pref?["BUNDLED_ASSETS_DEFAULT_STATE_UPDATED"] = stateUpdated
        }
    }
    
    static func isBundledAssetsDefaultStateUpdated() -> Bool {
        return readPreferenceValue(of: "BUNDLED_ASSETS_DEFAULT_STATE_UPDATED") ?? false
    }
    
    static func lastNotifiedDateForDisabledExtension() -> Date? {
        guard let seconds:Int = readPreferenceValue(of: "LAST_NOTIFIED_DATE_FOR_DISABLED_EXTENSION") else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }
    
    static func setLastNotifiedDateForDisabledExtension(_ date: Date) {
        writePreferenceValue { (pref) in
            pref?["LAST_NOTIFIED_DATE_FOR_DISABLED_EXTENSION"] = Int(date.timeIntervalSince1970.rounded())
        }
    }
    
    static func setLaunchAppOnUserLogin(_ launch: Bool) {
        writePreferenceValue { (pref) in
            pref?["LAUNCH_APP_ON_USER_LOGIN"] = launch
        }
    }
    
    static func isLaunchAppOnUserLogin() -> Bool {
        return readPreferenceValue(of: "LAUNCH_APP_ON_USER_LOGIN") ?? false
    }
    
    static func setFilterList(identifier: String, enabled: Bool) {
        writePreferenceValue { (pref) in
            pref?["\(identifier)_active"] = enabled
        }
    }
    
    static func isFilterListEnabled(identifier: String) -> Bool {
        return readPreferenceValue(of: "\(identifier)_active") ?? false
    }
    
    static func setFilterList(identifier: String, rulesCount: Int) {
        writePreferenceValue { (pref) in
            pref?[identifier] = rulesCount
        }
    }
    
    static func filterListRulesCount(identifier: String) -> Int {
        return readPreferenceValue(of: identifier) ?? 0
    }
    
    static func setPauseBlocking(_ pause: Bool) {
        writePreferenceValue { (pref) in
            pref?["PAUSE_BLOCKING"] = pause
        }
    }
    
    static func isBlockingPaused() -> Bool {
        return readPreferenceValue(of: "PAUSE_BLOCKING") ?? false
    }
    
    static func setOperatingSystem(_ os: String) {
        writePreferenceValue { (pref) in
            pref?["OS"] = os
        }
    }
    
    static func operatingSystem() -> String {
        return readPreferenceValue(of: "OS") ?? "Unknown"
    }
    
    static func setOperatingSystemVersion(_ osVersion: String) {
        writePreferenceValue { (pref) in
            pref?["OS_VERSION"] = osVersion
        }
    }
    
    static func operatingSystemVersion() -> String {
        return readPreferenceValue(of: "OS_VERSION") ?? "Unknown"
    }
    
    static func setSafariVersion(_ version: String) {
        writePreferenceValue { (pref) in
            pref?["SAFARI_VERSION"] = version
        }
    }
    
    static func safariVersion() -> String {
        return readPreferenceValue(of: "SAFARI_VERSION") ?? "Unknown"
    }
    
    static func setSafariLanguage(_ lang: String) {
        writePreferenceValue { (pref) in
            pref?["SAFARI_LANG"] = lang
        }
    }
    
    static func safariLanguage() -> String {
        return readPreferenceValue(of: "SAFARI_LANG") ?? "Unknown"
    }
    
    static func setUserId(_ userId: String) {
        writePreferenceValue { (pref) in
            pref?["USER_ID"] = userId
        }
    }
    
    static func userId() -> String? {
        return readPreferenceValue(of: "USER_ID")
    }
    
    static func incrementTotalPings() {
        writePreferenceValue { (pref) in
            pref?["TOTAL_PINGS"] = (totalPings() + 1)
        }
    }
    
    static func totalPings() -> Int {
        return readPreferenceValue(of: "TOTAL_PINGS") ?? 0
    }
    
    static func lastPingDate() -> Date? {
        guard let seconds:Int = readPreferenceValue(of: "LAST_PING_DATE") else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(seconds))
    }
    
    static func setLastPingDate(_ date: Date) {
        writePreferenceValue { (pref) in
            pref?["LAST_PING_DATE"] = Int(date.timeIntervalSince1970.rounded())
        }
    }
}
