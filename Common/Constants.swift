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

public struct Constants {
    
    static let DEBUG_LOG_ENABLED = false
    
    /// Group Identifier
    static let GROUP_IDENTIFIER = "GFKM76M39L.org.uBlockLLC.uBlock"
    static let SAFARI_CONTENT_BLOCKER_EXTENSION_IDENTIFIER = "org.uBlockLLC.uBlock.SafariContentBlocker"
    static let SAFARI_MENU_EXTENSION_IDENTIFIER = "org.uBlockLLC.uBlock.SafariMenu"
    
    // Removed due to app rejection by Apple to use the in-app purchase
    //static let DONATION_PAGE_URL = "https://www.ublock.org/donate/"
    
    //static let FAQ_PAGE_URL = "https://www.ublock.org/faq/"
    static let HELP_PAGE_URL = "https:/www.ublock.org/help/"
    static let UBLOCK_WEBSITE_URL = "https://www.ublock.org"
    
    static let CONTENT_BLOCKING_RULES_LIMIT = 50000
    static let SAFARI_EXTENSION_DISABLED_NOTIFICATION_DELAY_IN_MINUTES = 60 * 24 // 24 hours
    static let FILTER_LISTS_UPDATE_SCHEDULE_INTERVAL_IN_SECONDS = 60 * 60 * 24 * 4 // 4 DAYS
    static let ALLOW_ADS_FILTER_LIST_ID = "easylist_exceptionrules_content_blocker"
    static let ADS_FILTER_LIST_ID = "easylist_content_blocker"
    
    static let BUNDLED_FILTER_LISTS_UPDATE_DATE: Date = {
       var components = Calendar.current.dateComponents([], from: Date())
        components.setValue(2018, for: .year)
        components.setValue(05, for: .month)
        components.setValue(01, for: .day)
        components.setValue(12, for: .hour)
        components.setValue(00, for: .minute)
        components.setValue(00, for: .second)
        return Calendar.current.date(from: components)!
    }()
    
    struct AssetsUrls {
        private init() {}
        static let groupStorageFolder: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.GROUP_IDENTIFIER)
        static let assetsFolder: URL? = AssetsUrls.groupStorageFolder?.appendingPathComponent("Assets")
        static let thirdPartyFolder: URL? = AssetsUrls.assetsFolder?.appendingPathComponent("ThirdParty")
        static let contentBlockerFolder: URL? = AssetsUrls.assetsFolder?.appendingPathComponent("ContentBlocker")
        
        static let assetsChecksumUrl: URL? = AssetsUrls.assetsFolder?.appendingPathComponent("assets_checksum.json")
        static let mergedRulesUrl: URL? = AssetsUrls.contentBlockerFolder?.appendingPathComponent("merged_rules.json")
        static let emptyRulesUrl: URL? = AssetsUrls.contentBlockerFolder?.appendingPathComponent("empty_rules.json")
        
        static let whitelistUrl: URL? = AssetsUrls.assetsFolder?.appendingPathComponent("whitelist.json")
        
        static let userPreferenceUrl: URL? = AssetsUrls.assetsFolder?.appendingPathComponent("user_preference.json")
    }
    
    /// Observable flag to select whitelist in section when user click on `whitelist` from app menu bar
    static var shouldSelectWhitelist = Observable<Bool>(false)
    
    // ===== REST APIs =====
    public enum ApiEnv {
        case staging
        case live
    }
    private static let API_ENV: ApiEnv = .live
    public static var API_URL: String {
        switch API_ENV {
        case .staging:
            return "http://111.93.64.118/api"
        case .live:
            return "https://ping.ublock.org/api"
        }
    }
    public struct Api {
        static let checksum = "/checksums"
        static let filterlist = "/filterlist"
        static let pingData = "/stats"
    }
    // ===== END REST APIs =====
    
    public enum uBlockError: Error {
        case invalidApiUrl
    }
}
