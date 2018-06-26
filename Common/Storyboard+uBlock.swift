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

extension NSStoryboard {
    
    private class func mainStoryboard() -> NSStoryboard { return NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: Bundle.main) }
    
    class func mainVC() -> MainVC {
        return self.mainStoryboard().instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "MainVC")) as! MainVC
    }
    
    class func introVC() -> IntroVC {
        return self.mainStoryboard().instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "IntroVC")) as! IntroVC
    }
}
