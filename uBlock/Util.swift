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

class Util {
    private init() {}
    
    static func fetchExtensionStatus(_ completion: @escaping(_ contentBlockerEnabled: Bool, _ menuEnabled: Bool, _ error: Error?) -> Void) {
        var safariContentBlockerEnabled = false
        var safariMenuEnabled = false
        let group = DispatchGroup()
        var err: Error?
        group.enter()
        DispatchQueue.main.async(group: group) {
            SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Constants.SAFARI_CONTENT_BLOCKER_EXTENSION_IDENTIFIER) { (state, error) in
                guard let state = state else {
                    SwiftyBeaver.error(error ?? "")
                    err = error
                    group.leave()
                    return
                }
                
                safariContentBlockerEnabled = state.isEnabled
                group.leave()
            }
        }
        
        group.enter()
        DispatchQueue.main.async(group: group) {
            SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: Constants.SAFARI_MENU_EXTENSION_IDENTIFIER) { (state, error) in
                guard let state = state else {
                    SwiftyBeaver.error(error ?? "")
                    err = error
                    group.leave()
                    return
                }
                
                safariMenuEnabled = state.isEnabled
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(safariContentBlockerEnabled, safariMenuEnabled, err)
        }
    }
    
    static func scheduleJob(identifier: String,
                            interval: TimeInterval,
                            tolerance: TimeInterval = 1,
                            repeats: Bool,
                            execute: @escaping (@escaping NSBackgroundActivityScheduler.CompletionHandler) -> Void) -> NSBackgroundActivityScheduler {
        let job = NSBackgroundActivityScheduler(identifier: identifier)
        job.interval = interval
        job.tolerance = tolerance
        job.repeats = repeats
        //job.qualityOfService = .userInteractive
        job.schedule { (completion) in
            if job.shouldDefer {
                completion(.deferred)
                return
            }
            execute(completion)
        }
        return job
    }
}
