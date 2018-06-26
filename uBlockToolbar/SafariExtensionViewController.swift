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

import SafariServices
import SwiftyBeaver

class SafariExtensionViewController: SFSafariExtensionViewController {
    @IBOutlet weak var btnAllowAds: NSButton!
    @IBOutlet weak var btnPause: NSButton!
    @IBOutlet weak var btnSettings: NSButton!
    @IBOutlet weak var btnHelpAndFeedback: NSButton!
    @IBOutlet weak var pauseProgressView: NSProgressIndicator!
    @IBOutlet weak var allowAdsProgressView: NSProgressIndicator!
    @IBOutlet weak var allowAdsStackView: NSStackView!
    @IBOutlet weak var allowAdsLine: NSBox!
    @IBOutlet weak var warningBox: NSBox!
    @IBOutlet weak var menuBox: NSBox!
    
    fileprivate var assetsManagerStatusObserverRef: Disposable? = nil
    
    static let shared = SafariExtensionViewController()
    
    private var url: String?
    private var contentBlockerEnabled: Bool = true
    
    private let whitelistNotificationName = Notification.Name(rawValue: "\(Constants.SAFARI_MENU_EXTENSION_IDENTIFIER).whitelist")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (Constants.DEBUG_LOG_ENABLED) {
            SwiftyBeaver.addDestination(ConsoleDestination())
        }
        
        assetsManagerStatusObserverRef = AssetsManager.shared.status.didChange.addHandler(target: self, handler: SafariExtensionViewController.assetsManagerStatusChageObserver)
    }
    
    deinit {
        assetsManagerStatusObserverRef?.dispose()
    }
    
    private func observeContentBlockerState() {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Constants.SAFARI_CONTENT_BLOCKER_EXTENSION_IDENTIFIER) { (state, error) in
            guard let state = state else {
                SwiftyBeaver.error("Content blocker state error:\(String(describing: error))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.observeContentBlockerState()
                }
                return
            }
            SwiftyBeaver.debug("Content blocker state: \(state.isEnabled)")
            self.contentBlockerEnabled = state.isEnabled
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.observeContentBlockerState()
            }
        }
    }
    
    private func assetsManagerStatusChageObserver(data: (AssetsManagerStatus, AssetsManagerStatus)) {
        switch data.1 {
        case .mergeRulesStarted:
            allowAdsProgressView.isHidden = false
            allowAdsProgressView.startAnimation(nil)
        case .mergeRulesCompleted, .mergeRulesError:
            DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
                self.allowAdsProgressView.stopAnimation(nil)
                self.allowAdsProgressView.isHidden = true
                self.updateWhitelistButtonTitle()
                self.btnAllowAds.isEnabled = true
                self.reloadCurrentPage()
            })
            
        default:
            SwiftyBeaver.debug("idle")
        }
    }
    
    func onPopoverVisible(with url: String?) {
        self.url = url
        if contentBlockerEnabled {
            self.warningBox.isHidden = true
            self.menuBox.isHidden = false
            
            self.pauseProgressView.isHidden = true
            self.allowAdsProgressView.isHidden = true
            self.btnPause.isEnabled = true
            if self.url == nil {
                //allowAdsLine.isHidden = true
                //allowAdsStackView.isHidden = true
                self.btnAllowAds.isEnabled = false
            } else {
                //allowAdsLine.isHidden = false
                //allowAdsStackView.isHidden = false
                self.btnAllowAds.isEnabled = true
            }
            
            self.updateWhitelistButtonTitle()
            self.updatePauseButtonTitle()
        } else {
            self.warningBox.isHidden = false
            self.menuBox.isHidden = true
        }
    }
    
    private func updateWhitelistButtonTitle() {
        guard let url = self.url else {
            btnAllowAds.title = NSLocalizedString("Allow ads on this site", comment: "")
            return
        }
        
        if WhitelistManager.shared.exists(url) && WhitelistManager.shared.isEnabled(url) {
            btnAllowAds.title = NSLocalizedString("Block ads on this site", comment: "")
        } else {
            btnAllowAds.title = NSLocalizedString("Allow ads on this site", comment: "")
        }
    }
    
    private func updatePauseButtonTitle() {
        if PauseResumeBlockinManager.shared.isBlockingPaused() {
            btnPause.title = NSLocalizedString("Resume", comment: "")
        } else {
            btnPause.title = NSLocalizedString("Pause", comment: "")
        }
    }
    
    private func reloadCurrentPage() {
        SFSafariApplication.getActiveWindow(completionHandler: { (window) in
            window?.getActiveTab(completionHandler: { (tab) in
                tab?.getActivePage(completionHandler: { (page) in
                    page?.reload()
                })
            })
        })
    }
    
    @IBAction func pauseBlockingClick(_ sender: NSButton) {
        if PauseResumeBlockinManager.shared.isBlockingPaused() {
            PauseResumeBlockinManager.shared.resumeBlocking()
        } else {
            PauseResumeBlockinManager.shared.pauseBlocking()
        }
        
        pauseProgressView.isHidden = false
        pauseProgressView.startAnimation(nil)
        btnPause.isEnabled = false
        PauseResumeBlockinManager.shared.callReloadContentBlocker {
            let delay = TimeInterval(PauseResumeBlockinManager.shared.isBlockingPaused() ? 5 : 2)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                self.pauseProgressView.stopAnimation(nil)
                self.pauseProgressView.isHidden = true
                self.updatePauseButtonTitle()
                self.btnPause.isEnabled = true
                self.reloadCurrentPage()
            })
        }
    }
    
    @IBAction func addToWhitelistClick(_ sender: NSButton) {
        guard let url = self.url else {
            return
        }
        btnAllowAds.isEnabled = false
        if WhitelistManager.shared.exists(url) {
            if WhitelistManager.shared.isEnabled(url) {
                WhitelistManager.shared.remove(url)
            } else {
                WhitelistManager.shared.enable(url)
            }
        } else if (WhitelistManager.shared.isValid(url: url)) {
            WhitelistManager.shared.add(url)
        } else {
            AlertUtil.errorAlert(title: NSLocalizedString("Error", comment: ""),
                                 message: NSLocalizedString("Invalid url", comment: ""))
            return
        }
        
        DistributedNotificationCenter.default().post(name: whitelistNotificationName,
                                                     object: Constants.SAFARI_MENU_EXTENSION_IDENTIFIER)
    }
    
    @IBAction func settingsClick(_ sender: NSButton) {
        NSWorkspace.shared.launchApplication("uBlock")
    }
    
    @IBAction func helpAndFeedbackClick(_ sender: NSButton) {
        Util.openUrlInSafari(Constants.HELP_PAGE_URL)
    }
}
