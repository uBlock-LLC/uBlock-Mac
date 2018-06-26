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
import Punycode_Cocoa

enum WhitelistManagerStatus {
    case idle
    
    case whitelistUpdateStarted
    case whitelistUpdateCompleted
    case whitelistUpdateError    
}

class WhitelistManager: NSObject {
    static let shared: WhitelistManager = WhitelistManager()
    
    var status: Observable<WhitelistManagerStatus> = Observable(.idle)
    
    func isValid(url: String) -> Bool {
        let host = removeUrlComponentsAfterHost(url: url)
        let urlRegEx = "((?:http|https)://)?(((?:www)?|(?:[a-zA-z0-9]{1,})?)\\.)?[\\w\\d\\-_]+\\.(\\w{2,}?|(xn--\\w{2,})?)(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let result = urlTest.evaluate(with: host)
        return result
    }
    
    func removeUrlComponentsAfterHost(url: String) -> String {
        var host = ""
        var firstSlashRange: Range<String.Index>?
        if let protocolRange = url.range(of: "://") {
            let searchRange = Range<String.Index>(uncheckedBounds: (lower: protocolRange.upperBound, upper: url.endIndex))
            firstSlashRange = url.range(of: "/", options: .literal, range: searchRange, locale: Locale.current)
        } else {
            firstSlashRange = url.range(of: "/", options: .literal, range: nil, locale: Locale.current)
        }
        host = String(url[..<(firstSlashRange?.lowerBound ?? url.endIndex)])
        return host
    }
    
    func add(_ url: String) {
        self.status.set(newValue: .whitelistUpdateStarted)
        let normalizedUrl = normalizeUrl(url)
        let rule = prepareRule(normalizedUrl)
        let whitelist: [String : Any] = ["domain": normalizedUrl, "active": canEnable(), "rule": rule]
        
        var whitelists: [[String:Any]]? = getAll() ?? []
        whitelists?.append(whitelist)
        saveAsync(whitelists) {
            self.status.set(newValue: .whitelistUpdateCompleted)
            self.status.set(newValue: .idle)
            self.callAssetMerge()
        }
    }
    
    func remove(_ url: String) {
        self.status.set(newValue: .whitelistUpdateStarted)
        let normalizedUrl = normalizeUrl(url)
        
        let whitelists: [[String:Any]]? = getAll() ?? []
        let newWhitelists = whitelists?.filter({ (whitelist) -> Bool in
            guard let domain = whitelist["domain"] as? String else { return false }
             return domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != normalizedUrl.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        })
        saveAsync(newWhitelists) {
            self.status.set(newValue: .whitelistUpdateCompleted)
            self.status.set(newValue: .idle)
            self.callAssetMerge()
        }
    }
    
    func enable(_ url: String) {
        self.status.set(newValue: .whitelistUpdateStarted)
        guard var whitelists = getAll() else {
            status.set(newValue: .idle)
            return
        }
        
        guard let (whitelist, index) = findEntryAndIndex(of: url, in: whitelists) else {
            status.set(newValue: .idle)
            return
        }
        var currentWhitelist = whitelist
        currentWhitelist["active"] = true
        whitelists[index] = currentWhitelist
        
        saveAsync(whitelists) {
            self.status.set(newValue: .whitelistUpdateCompleted)
            self.status.set(newValue: .idle)
            self.callAssetMerge()
        }
    }
    
    func disable(_ url: String) {
        self.status.set(newValue: .whitelistUpdateStarted)
        guard var whitelists = getAll() else {
            status.set(newValue: .idle)
            return
        }
        
        guard let (whitelist, index) = findEntryAndIndex(of: url, in: whitelists) else {
            status.set(newValue: .idle)
            return
        }
        var currentWhitelist = whitelist
        currentWhitelist["active"] = false
        whitelists[index] = currentWhitelist
        
        saveAsync(whitelists) {
            self.status.set(newValue: .whitelistUpdateCompleted)
            self.status.set(newValue: .idle)
            self.callAssetMerge()
        }
    }
    
    func isEnabled(_ url: String) -> Bool {
        guard let whitelists = getAll() else { return false }
        guard let (whitelist, _) = findEntryAndIndex(of: url, in: whitelists) else {
            return false
        }
        return whitelist["active"] as? Bool ?? false == true
    }
    
    func exists(_ url: String) -> Bool {
        guard let whitelists = getAll() else { return false }
        guard let (_, _) = findEntryAndIndex(of: url, in: whitelists) else {
            return false
        }
        return true
    }
    
    func getAllItems() -> [Item]? {
        guard let whitelists = getAll() else { return [] }
        var whitelistItems: [Item]? = []
        for whitelist in whitelists {
            let id = whitelist["domain"] as? String
            let name = whitelist["domain"] as? String
            let active = whitelist["active"] as? Bool
            whitelistItems?.append(Item(id: id, name: name, active: active, desc: ""))
        }
        if whitelistItems?.isEmpty ?? true {
            whitelistItems?.append(Item(id: Item.EMPTY_WHITELIST_ITEM_ID, name: "", active: true))
        }
        return whitelistItems?.reversed()
    }
    
    func getActiveWhitelistRules() -> [[String:Any]]? {
        guard let whitelists = getAll() else { return [] }
        let activeWhitelists = whitelists.filter { (whitelist) -> Bool in
            return whitelist["active"] as? Bool ?? false
            }.compactMap { (activeWhitelist) -> [String: Any]? in
                return activeWhitelist["rule"] as? [String: Any]
        }
        return activeWhitelists
    }
    
    private func callAssetMerge() {
        AssetsManager.shared.requestMerge()
    }
    
    func canEnable() -> Bool {
        guard let mergedRules: [[String:Any]]? = FileManager.default.readJsonFile(at: Constants.AssetsUrls.mergedRulesUrl) else { return true }
        let activeRulesCount = mergedRules?.count ?? 0
        return (activeRulesCount + 1) <= Constants.CONTENT_BLOCKING_RULES_LIMIT
    }
    
    private func getAll() -> [[String:Any]]? {
        let whitelists: [[String:Any]]? = FileManager.default.readJsonFile(at: Constants.AssetsUrls.whitelistUrl)
        return whitelists
    }
    
    private func prepareRule(_ url: String) -> [String: Any] {
        let rule = WhitelistRulesMaker.shared.makeRule(for: url)
        return rule
    }
    
    private func save(_ rules: [[String:Any]]?) {
        FileManager.default.writeJsonFile(at: Constants.AssetsUrls.whitelistUrl, with: rules)
    }
    
    private func saveAsync(_ rules: [[String:Any]]?, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .background).async {
            self.save(rules)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func removeProtocol(from url: String) -> String {
        let dividerRange = url.range(of: "://")
        guard let divide = dividerRange?.upperBound else { return url }
        let path = String(url[divide...])
        return path
    }
    
    private func findEntryAndIndex(of url: String, in whitelists: [[String:Any]]) -> ([String:Any], Int)? {
        let normalizedUrl = normalizeUrl(url)
        guard let currentUrlWhitelist = whitelists.filter({ (whitelist) -> Bool in
            guard let domain = whitelist["domain"] as? String else { return false }
            return domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedUrl.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }).first else {
            return nil
        }
        
        guard let index = whitelists.index(where: { (whitelist) -> Bool in
            guard let domain = whitelist["domain"] as? String else { return false }
            return domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedUrl.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }) else {
            return nil
        }
        
        return (currentUrlWhitelist, index)
    }
    
    func normalizeUrl(_ url: String) -> String {
        let host = removeUrlComponentsAfterHost(url: url)
        var normalizedUrl = removeProtocol(from: host)
        if normalizedUrl.starts(with: "www.") {
            normalizedUrl = normalizedUrl.replacingOccurrences(of: "www.", with: "")
        }
        normalizedUrl = (normalizedUrl as NSString).decodedURL ?? normalizedUrl
        return normalizedUrl
    }
}
