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

class WhitelistRulesMaker: NSObject {
    
    static let shared: WhitelistRulesMaker = WhitelistRulesMaker()
    private override init() {}
    
    func makeRule(for url: String) -> [String: Any] {
        let trigger = prepareTriggerV2(url)
        let action = prepareAction(url)
        let rule = ["trigger": trigger, "action": action]
        return rule
    }
    
    private func prepareUrlFilter(_ url: String) -> String {
        var wwwPattern = ""
        if !(url.starts(with: "www") || url.starts(with: "*")) {
            wwwPattern = escapeDot("(www.)?")
        }
        var filter = escapeDot(url)
        filter = replaceStarIfExists(filter)
        filter = (filter as NSString).encodedURL ?? filter
        filter = "^https?://\(wwwPattern)\(filter)"
        return filter
    }
    
    private func escapeDot(_ url: String) -> String {
        return url.replacingOccurrences(of: ".", with: "\\.")
    }
    
    private func replaceStarIfExists(_ url: String) -> String {
        return url.replacingOccurrences(of: "*", with: ".*")
    }
    
    private func prepareTrigger(_ url: String) -> [String: Any] {
        let urlFilter = prepareUrlFilter(url)
        let trigger: [String: Any] = ["url-filter": urlFilter,
                                      "resource-type" : [
                                        "image", "style-sheet", "script", "svg-document", "media",
                                        "font", "media", "raw", "document", "popup"]]
        return trigger
    }
    
    private func prepareTriggerV2(_ url: String) -> [String: Any] {
        let trigger: [String: Any] = ["url-filter": ".*", "if-domain": ["*\(url)"]]
        return trigger
    }
    
    private func prepareAction(_ url: String) -> [String: String] {
        let action = ["type": "ignore-previous-rules"]
        return action
    }
}
