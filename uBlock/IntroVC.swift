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
import ServiceManagement
import SwiftyBeaver

protocol IntroVCDelegate {
    func startApp()
}

class IntroVC: NSViewController {
    
    @IBOutlet weak var uBlockReadyView: NSView!
    @IBOutlet weak var introView: NSView!
    @IBOutlet weak var btnLaunch: NSButton!
    @IBOutlet weak var lblActivationNote: NSTextField!
    @IBOutlet var infoTextView: NSTextView!
    
    var delegate: IntroVCDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkExtensionIsEnabled()
        highlightActivationNote()
        
        infoTextView.delegate = self
        if let infoFilePath = Bundle.main.path(forResource: "uBlockInfo", ofType: "rtfd") {
            infoTextView.readRTFD(fromFile: infoFilePath)
        }
    }
    
    private func highlightActivationNote() {
        let highlightedNotePart = NSLocalizedString("Please activate uBlock and the uBlock Safari Icon Safari Extensions", comment: "")
        let note = NSLocalizedString("Please activate uBlock and the uBlock Safari Icon Safari Extensions and then return to uBlock.", comment: "")
        let textParagraph:NSMutableParagraphStyle = NSMutableParagraphStyle()
        textParagraph.alignment = .center
        lblActivationNote.attributedStringValue = note.toAttributed(highlight: highlightedNotePart,
                                                                    with: [.font : NSFont(name: "LucidaGrande-Bold",
                                                                                          size: lblActivationNote.font?.pointSize ?? 16)!,
                                                                           .paragraphStyle : textParagraph
            ])
    }
    
    private func checkExtensionIsEnabled() {
        var safariContentBlockerEnabled = false
        var safariMenuEnabled = false
        let group = DispatchGroup()
        
        group.enter()
        DispatchQueue.main.async(group: group) {
            SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Constants.SAFARI_CONTENT_BLOCKER_EXTENSION_IDENTIFIER) { (state, error) in
                guard let state = state else {
                    SwiftyBeaver.error(error ?? "")
                    safariContentBlockerEnabled = false
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
                    safariMenuEnabled = false
                    group.leave()
                    return
                }
                
                safariMenuEnabled = state.isEnabled
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if !safariContentBlockerEnabled {
                // TODO: Show safari content blocker not enabled
                self.introView.isHidden = false
                self.uBlockReadyView.isHidden = true
            } else if !safariMenuEnabled {
                // TODO: Show safari menu not enabled
                self.introView.isHidden = false
                self.uBlockReadyView.isHidden = true
            } else if safariContentBlockerEnabled && safariMenuEnabled {
                // TODO: Show intro screen
                self.introView.isHidden = true
                self.uBlockReadyView.isHidden = false
            }
            
            if !UserPref.isIntroScreenShown() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    SwiftyBeaver.debug("check extension is enabled or not....")
                    self.checkExtensionIsEnabled()
                })
            }
        }
    }
    
    // Removed due to app rejection by Apple to use the in-app purchase
    /*private func openDonationPageInSafari() {
        if !NSWorkspace.shared.openFile(Constants.DONATION_PAGE_URL, withApplication: "Safari") {
            guard let url = URL(string: Constants.DONATION_PAGE_URL) else { return }
            NSWorkspace.shared.open(url)
        }
    }*/
    
    @IBAction func launchClick(_ sender: NSButton) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: Constants.SAFARI_CONTENT_BLOCKER_EXTENSION_IDENTIFIER, completionHandler: { (error) in
            if let error = error {
                SwiftyBeaver.error("safari extension preference error: \(error.localizedDescription)")
            } else {
                SwiftyBeaver.debug("safari extension preference opened")
            }
        })
    }
    
    @IBAction func startAppOnLoginClick(_ sender: NSButton) {
        let launcherAppId = "org.uBlockLLC.LauncherApp"
        if !SMLoginItemSetEnabled(launcherAppId as CFString, sender.state == .on ? true : false) {
            SwiftyBeaver.error("Error in setting launcher app")
        } else {
            UserPref.setLaunchAppOnUserLogin(sender.state == .on ? true : false)
        }
    }
    
    @IBAction func startSurfingWebClick(_ sender: NSButton) {
        // Removed due to app rejection by Apple to use the in-app purchase
        /*if !UserPref.isDonationPageShown() {
            self.openDonationPageInSafari()
        }*/
        self.delegate?.startApp()
    }
}

extension IntroVC : NSTextViewDelegate {
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        guard let url = link as? URL else {
            return false
        }
        
        if url.absoluteString.starts(with: "http") {
            if NSWorkspace.shared.openFile(url.absoluteString, withApplication: "Safari") {
                return true
            } else {
                NSWorkspace.shared.open(url)
                return true
            }
        }
        
        return false
    }
}
