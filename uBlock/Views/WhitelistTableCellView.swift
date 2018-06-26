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

protocol WhitelistTableCellViewDelegate {
    func whitelistTableCellView(_ cell: WhitelistTableCellView, enabledItem item: Item?)
    func whitelistTableCellView(_ cell: WhitelistTableCellView, disabledItem item: Item?)
    func whitelistTableCellView(_ cell: WhitelistTableCellView, deleteItem item: Item?)
}

class WhitelistTableCellView: NSTableCellView {

    @IBOutlet weak var checkbox: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var progressView: NSProgressIndicator!
    @IBOutlet weak var deleteProgressView: NSProgressIndicator!
    @IBOutlet weak var btnDelete: NSButton!
    
    private var item: Item? = nil
    
    private var delegate: WhitelistTableCellViewDelegate?
    
    private var assetsManagerStatusObserverRef: Disposable?
    
    override func awakeFromNib() {
        lblTitle.preferredMaxLayoutWidth = 0
        lblTitle.maximumNumberOfLines = 2
        progressView.isHidden = true
        assetsManagerStatusObserverRef = AssetsManager.shared.status.didChange.addHandler(target: self, handler: WhitelistTableCellView.assetsManagerStatusChageObserver)
    }
    
    deinit {
        assetsManagerStatusObserverRef?.dispose()
    }
    
    func update(_ item: Item?, delegate: WhitelistTableCellViewDelegate?) {
        self.item = item
        self.delegate = delegate
        checkbox.state = (self.item?.active ?? false) ? .on : .off
        lblTitle.stringValue = self.item?.name ?? ""
        checkbox.isEnabled = AssetsManager.shared.status.get() == .idle
        btnDelete.isEnabled = AssetsManager.shared.status.get() == .idle
        showProgress(false)
        showDeleteProgress(false)
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
    
    func showDeleteProgress(_ show: Bool) {
        deleteProgressView.isHidden = !show
        btnDelete.isHidden = show
        if show {
            deleteProgressView.startAnimation(nil)
        } else {
            deleteProgressView.stopAnimation(nil)
        }
    }
    
    private func assetsManagerStatusChageObserver(data: (AssetsManagerStatus, AssetsManagerStatus)) {
        switch data.1 {
        case .mergeRulesStarted:
            checkbox.isEnabled = false
            btnDelete.isEnabled = false
        case .mergeRulesCompleted, .mergeRulesError:
            checkbox.isEnabled = true
            btnDelete.isEnabled = true
        default:
            SwiftyBeaver.debug("idle")
        }
    }
    
    @IBAction func checkboxClick(_ sender: NSButton) {
        if sender.state == .on {
            self.delegate?.whitelistTableCellView(self, enabledItem: self.item)
        } else {
            self.delegate?.whitelistTableCellView(self, disabledItem: self.item)
        }
    }
    
    @IBAction func deleteClick(_ sender: NSButton) {
        self.delegate?.whitelistTableCellView(self, deleteItem: self.item)
    }
}
