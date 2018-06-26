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
import SwiftyBeaver

protocol FilterListTableCellViewDelegate {
    func filterListTableCellView(_ cell: FilterListTableCellView, enabledItem item: Item?)
    func filterListTableCellView(_ cell: FilterListTableCellView, disabledItem item: Item?)
}

class FilterListTableCellView: NSTableCellView {
    
    @IBOutlet weak var checkbox: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblRulesCount: NSTextField!
    @IBOutlet weak var progressView: NSProgressIndicator!
    
    private var item: Item? = nil
    private var delegate: FilterListTableCellViewDelegate?
    
    private var assetsManagerStatusObserverRef: Disposable?
    
    private var adsEnabled: Bool?
    private var currentFilterListId: String?
    
    override func awakeFromNib() {
        lblTitle.preferredMaxLayoutWidth = 0
        lblTitle.maximumNumberOfLines = 1
        
        lblRulesCount.preferredMaxLayoutWidth = 0
        lblRulesCount.maximumNumberOfLines = 1
        
        progressView.isHidden = true
        
        assetsManagerStatusObserverRef = AssetsManager.shared.status.didChange.addHandler(target: self, handler: FilterListTableCellView.assetsManagerStatusChageObserver)
    }
    
    deinit {
        assetsManagerStatusObserverRef?.dispose()
    }
    
    func update(_ item: Item?, delegate: FilterListTableCellViewDelegate?, adsEnabled: Bool?) {
        self.item = item
        self.delegate = delegate
        self.adsEnabled = adsEnabled
        
        checkbox.state = (self.item?.active ?? false) ? .on : .off
        lblTitle.stringValue = self.item?.name ?? ""
        
        let assetManagerStatus = AssetsManager.shared.status.get()
        if item?.id ?? "" == Constants.ALLOW_ADS_FILTER_LIST_ID {
            checkbox.isEnabled = assetManagerStatus == .idle && (adsEnabled ?? true)
            lblTitle.isEnabled = assetManagerStatus == .idle && (adsEnabled ?? true)
            lblRulesCount.isHidden = true
            lblTitle.textColor = {
                if assetManagerStatus == .idle {
                    return (adsEnabled ?? false) ? .black : .gray
                } else {
                    return currentFilterListId == item?.id ? .black : ((adsEnabled ?? false) ? .black : .gray)
                }
            }()
        } else {
            checkbox.isEnabled = assetManagerStatus == .idle
            lblTitle.isEnabled = assetManagerStatus == .idle
            lblTitle.textColor = .black
            var rulesCount = ""
            if let count = self.item?.rulesCount {
                rulesCount = "(\(count) \(NSLocalizedString("Rules", comment: "")))"
            }
            lblRulesCount.isHidden = false
            lblRulesCount.stringValue = rulesCount
        }
        
        // To display rules count, excluding allow ads rules count, comment following line
        lblRulesCount.isHidden = true
    }
    
    func showProgress(_ show: Bool) {
        checkbox.isHidden = show
        progressView.isHidden = !show
        if show {
            progressView.startAnimation(nil)
        } else {
            progressView.stopAnimation(nil)
        }
    }
    
    private func assetsManagerStatusChageObserver(data: (AssetsManagerStatus, AssetsManagerStatus)) {
        switch data.1 {
        case .mergeRulesStarted:
            checkbox.isEnabled = false
        case .mergeRulesCompleted, .mergeRulesError:
            checkbox.isEnabled = true
            currentFilterListId = nil
        default:
            SwiftyBeaver.debug("idle")
        }
    }
    
    @IBAction func checkboxClick(_ sender: NSButton) {
        currentFilterListId = item?.id
        if sender.state == .on {
            self.delegate?.filterListTableCellView(self, enabledItem: self.item)
        } else {
            self.delegate?.filterListTableCellView(self, disabledItem: self.item)
        }
    }
}
