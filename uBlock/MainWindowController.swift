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

class MainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        let appDelegate = NSApplication.shared.delegate as? AppDelegate
        appDelegate?.mainWindow = self.window
        if UserPref.isIntroScreenShown() {
            self.contentViewController = NSStoryboard.mainVC()
            self.window?.titleVisibility = .visible
        } else {
            let introVC = NSStoryboard.introVC()
            introVC.delegate = self
            self.contentViewController = introVC
            self.window?.titleVisibility = .hidden
        }
    }
}

extension MainWindowController: IntroVCDelegate {
    func startApp() {
        UserPref.setIntroScreenShown(true)
        self.contentViewController = nil
        self.contentViewController = NSStoryboard.mainVC()
        self.window?.titleVisibility = .visible
    }
}
