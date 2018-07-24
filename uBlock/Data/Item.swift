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

class Item : NSObject {
    static let EMPTY_WHITELIST_ITEM_ID = "EMPTY_WHITELIST"
    static let WHITELIST_ITEM_ID = "WHITELIST"
    static let ALL_FILTER_LIST_INACTIVE_ITEM_ID = "INACTIVE_FILTER_LIST"
    static let DONATE_ITEM_ID = "DONATE"
    static let DEFAULT_FILTER_LIST_ITEM_ID = "DEFAULT_FILTERLIST"
    
    var id: String? = nil
    var name: String? = nil
    var active: Bool? = nil
    var desc: String? = nil
    var rulesCount: Int? = nil
    var image: String? = nil
    
    var filterListItems: [Item]? = nil
    
    init(id: String?, name: String?, active: Bool?, desc: String? = nil, rulesCount: Int? = nil, filterListItems: [Item]? = nil) {
        self.id = id
        self.name = name
        self.active = active
        self.desc = desc
        self.rulesCount = rulesCount
        self.filterListItems = filterListItems
    }
    
    override var description: String {
        return "\(id ?? ""): \(active ?? false)"
    }
}
