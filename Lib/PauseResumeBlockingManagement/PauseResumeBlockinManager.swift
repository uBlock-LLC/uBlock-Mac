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

class PauseResumeBlockinManager: NSObject {
    static let shared: PauseResumeBlockinManager = PauseResumeBlockinManager()
    
    func pauseBlocking() {
        UserPref.setPauseBlocking(true)
    }
    
    func resumeBlocking() {
        UserPref.setPauseBlocking(false)
    }
    
    func isBlockingPaused() -> Bool {
        return UserPref.isBlockingPaused()
    }
    
    func callReloadContentBlocker(_ completion: @escaping () -> Void) {
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: Constants.SAFARI_CONTENT_BLOCKER_EXTENSION_IDENTIFIER, completionHandler: { (error) in
            if let error = error {
                SwiftyBeaver.error("[ASSETS_MANAGER]: Error in reloading content blocker \(error)")
            } else {
                SwiftyBeaver.debug("[ASSETS_MANAGER]: Content blocker reloaded successfully")
            }
            DispatchQueue.main.async {
                completion()
            }
            
        })
    }
}
