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
import SafariServices
import SwiftyBeaver

enum AssetsManagerStatus {
    case idle
    
    case filterUpdateStarted
    case filterUpdateCompleted
    case filterUpdateError
    
    case mergeRulesStarted
    case mergeRulesCompleted
    case mergeRulesError
    
}

class AssetsManager: NSObject {
    
    static let shared: AssetsManager = AssetsManager()
    
    var status: Observable<AssetsManagerStatus> = Observable(.idle)
    
    private override init() {
        super.init()        
    }
    
    func initialize() {
        copyAssetsToGroupStorageIfNotExists()
    }
    
    private func copyAssetsToGroupStorageIfNotExists() {
        guard let destAssetsDirUrl = Constants.AssetsUrls.assetsFolder else { return }
        if !FileManager.default.fileExists(atPath: destAssetsDirUrl.path) {
            guard let srcAssetsDirUrl = Bundle.main.url(forResource: "Assets", withExtension: nil) else { return }
            do {
                try FileManager.default.copyItem(at: srcAssetsDirUrl, to: destAssetsDirUrl)
                UserPref.setFilterListsUpdatedDate(Constants.BUNDLED_FILTER_LISTS_UPDATE_DATE)
                UserPref.setBundledAssetsDefaultStateUpdated(false)
            } catch {
                SwiftyBeaver.error(error)
            }
        }
    }

    func requestFilterUpdate() {
        if self.status.get() != .idle {
            return
        }
        
        self.status.set(newValue: .filterUpdateStarted)
        AssetDownloader.shared.start { (downloadStatus) in
            if downloadStatus != .completed {
                self.status.set(newValue: .filterUpdateError)
                self.status.set(newValue: .idle)
                return
            }
            
            self.status.set(newValue: .filterUpdateCompleted)
            self.status.set(newValue: .idle)
            self.requestMerge()
        }
    }
    
    func requestMerge() {
        if self.status.get() != .idle {
            return
        }
        
        self.status.set(newValue: .mergeRulesStarted)
        AssetMerger.shared.start({ (mergeStatus) in
            SFContentBlockerManager.reloadContentBlocker(withIdentifier: Constants.SAFARI_CONTENT_BLOCKER_EXTENSION_IDENTIFIER, completionHandler: { (error) in
                if let error = error {
                    SwiftyBeaver.error("[ASSETS_MANAGER]: Error in reloading content blocker \(error)")
                } else {
                    SwiftyBeaver.debug("[ASSETS_MANAGER]: Content blocker reloaded successfully")
                }
                DispatchQueue.main.async {
                    self.status.set(newValue: mergeStatus == .completed ? .mergeRulesCompleted : .mergeRulesError)
                    self.status.set(newValue: .idle)
                }
            })
        })
    }
}
