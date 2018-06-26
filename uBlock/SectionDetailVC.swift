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

protocol SectionDetailVCDelegate {
    func onTooManyRulesActiveError()
}

class SectionDetailVC: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    var items: [Item]? = nil
    var delegate: SectionDetailVCDelegate?
    
    fileprivate var whitelistManagerStatusObserverRef: Disposable? = nil
    fileprivate var assetsManagerStatusObserverRef: Disposable? = nil
    fileprivate var currentProcessingItemId: String?
    fileprivate var deletingWhitelistItem: Bool = false
    
    private var isWhitelist: Bool = false
    
    private var adsEnabled: Bool?
    
    private let whitelistNotificationName = Notification.Name(rawValue: "\(Constants.SAFARI_MENU_EXTENSION_IDENTIFIER).whitelist")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        whitelistManagerStatusObserverRef = WhitelistManager.shared.status.didChange.addHandler(target: self, handler: SectionDetailVC.whitelistManagerStatusChageObserver)
        assetsManagerStatusObserverRef = AssetsManager.shared.status.didChange.addHandler(target: self, handler: SectionDetailVC.assetsManagerStatusChageObserver)
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(self.updateWhitelist),
                                                            name: whitelistNotificationName,
                                                            object: Constants.SAFARI_MENU_EXTENSION_IDENTIFIER)
    }
    
    @objc private func updateWhitelist() {
        if !isWhitelist { return }
        let whitelists = WhitelistManager.shared.getAllItems()
        self.items?.removeAll()
        self.items = (self.items ?? []) + (whitelists ?? [])
        self.tableView.reloadData()
    }
    
    func updateItems(_ items: [Item]?, title: String, itemId: String) {
        self.items = items
        
        switch itemId {
        case Item.WHITELIST_ITEM_ID:
            isWhitelist = true
        default:
            isWhitelist = false
        }
        
        tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: showOrHideFilterListWarning)
    }
    
    func onWhitelisting(url: String?) {
        currentProcessingItemId = url
    }
    
    private func whitelistManagerStatusChageObserver(data: (WhitelistManagerStatus, WhitelistManagerStatus)) {
        switch data.1 {
        case .whitelistUpdateCompleted:
            if !deletingWhitelistItem {
                updateWhitelist()
            }
        default:
            SwiftyBeaver.debug("idle")
        }
    }
    
    private func findFilterListCellById(_ filterListId: String?) -> FilterListTableCellView? {
        if isWhitelist { return nil }
        
        guard let cellIndex = self.items?.index(where: { (item) -> Bool in
            return item.id == filterListId
        }) else { return nil }
        
        let cell = self.tableView.view(atColumn: 0, row: cellIndex, makeIfNecessary: true) as? FilterListTableCellView
        return cell
    }
    
    private func findWhitelistCellByUrl(_ whitelistUrl: String?) -> WhitelistTableCellView? {
        if !isWhitelist { return nil }
        
        guard let cellIndex = self.items?.index(where: { (item) -> Bool in
            return item.id == whitelistUrl
        }) else { return nil }
        
        let cell = self.tableView.view(atColumn: 0, row: cellIndex, makeIfNecessary: true) as? WhitelistTableCellView
        return cell
    }
    
    private func assetsManagerStatusChageObserver(data: (AssetsManagerStatus, AssetsManagerStatus)) {
        switch data.1 {
        case .mergeRulesStarted:
            if isWhitelist {
                let whitelistCell = findWhitelistCellByUrl(currentProcessingItemId)
                if deletingWhitelistItem {
                    whitelistCell?.showDeleteProgress(true)
                } else {
                    whitelistCell?.showProgress(true)
                }
            } else {
                if AppMenuBar.lastFilterListMenuOperation > 0 {
                    if AppMenuBar.lastFilterListMenuOperation == AppMenuBar.ADS_CLICKED {
                        currentProcessingItemId = Constants.ADS_FILTER_LIST_ID
                    } else if AppMenuBar.lastFilterListMenuOperation == AppMenuBar.ALLOW_ADS_CLICKED {
                        currentProcessingItemId = Constants.ALLOW_ADS_FILTER_LIST_ID
                    }
                }
                let filterListCell = findFilterListCellById(currentProcessingItemId)
                filterListCell?.showProgress(true)
            }
        case .mergeRulesCompleted, .mergeRulesError:
            if isWhitelist {
                let whitelistCell = findWhitelistCellByUrl(currentProcessingItemId)
                if deletingWhitelistItem {
                    whitelistCell?.showDeleteProgress(false)
                } else {
                    whitelistCell?.showProgress(false)
                }
                currentProcessingItemId = nil
                deletingWhitelistItem = false
                updateWhitelist()
            } else {
                let filterListCell = findFilterListCellById(currentProcessingItemId)
                filterListCell?.showProgress(false)
                currentProcessingItemId = nil
                AppMenuBar.lastFilterListMenuOperation = 0
                tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: showOrHideFilterListWarning)
            }
            
        default:
            SwiftyBeaver.debug("idle")
        }
    }
    
    deinit {
        whitelistManagerStatusObserverRef?.dispose()
        assetsManagerStatusObserverRef?.dispose()
        DistributedNotificationCenter.default().removeObserver(self, name: whitelistNotificationName, object: Constants.SAFARI_MENU_EXTENSION_IDENTIFIER)
    }
    
    fileprivate func showOrHideFilterListWarning() {
        if isWhitelist { return }
        
        guard var _ = self.items?.index(where: { (item) -> Bool in
            return item.active == true && item.id ?? "" != Item.ALL_FILTER_LIST_INACTIVE_ITEM_ID
        }) else {
            // show warning
            guard let _ = self.items?.index(where: { (item) -> Bool in
                return item.id ?? "" == Item.ALL_FILTER_LIST_INACTIVE_ITEM_ID
            }) else {
                self.items?.insert(Item(id: Item.ALL_FILTER_LIST_INACTIVE_ITEM_ID, name: "", active: true), at: 0)
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: IndexSet(integer: 0), withAnimation: .effectFade)
                self.tableView.endUpdates()
                self.tableView.reloadData()
                AlertUtil.displayNotification(title: NSLocalizedString("Filter Lists", comment: ""),
                                              message: NSLocalizedString("uBlock is no longer blocking any Ads", comment: ""))
                return
            }
            return
        }
        
        // hide warning
        guard let idx = self.items?.index(where: { (item) -> Bool in
            return item.id ?? "" == Item.ALL_FILTER_LIST_INACTIVE_ITEM_ID
        }) else {
            return
        }
        self.tableView.beginUpdates()
        self.tableView.removeRows(at: IndexSet(integer: idx), withAnimation: .effectFade)
        self.items = items?.filter({ (item) -> Bool in
            return item.id ?? "" != Item.ALL_FILTER_LIST_INACTIVE_ITEM_ID
        })
        self.tableView.endUpdates()
        AlertUtil.displayNotification(title: NSLocalizedString("Filter Lists", comment: ""),
                                      message: NSLocalizedString("uBlock is blocking the Ads again.", comment: ""))
    }
}

// MARK:- Table view data source
// MARK:-
extension SectionDetailVC : NSTableViewDataSource, NSTableViewDelegate {
    
    // Item Count
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        let itemData = items?[row]
        
        if isWhitelist {
            if itemData?.id ?? "" == Item.EMPTY_WHITELIST_ITEM_ID {
                let emptyWhitelistItemView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EmptyWhitelistTableCellView"), owner: self)
                return emptyWhitelistItemView
            } else {
                let whitelistItemView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "WhitelistTableCellView"), owner: self)
                guard let whitelistCollectionViewItem = whitelistItemView as? WhitelistTableCellView else { return whitelistItemView }
                
                whitelistCollectionViewItem.update(itemData, delegate: self)
                if let currentWhitelistUrl = self.currentProcessingItemId, currentWhitelistUrl == itemData?.id, AssetsManager.shared.status.get() != .idle {
                    if deletingWhitelistItem {
                        whitelistCollectionViewItem.showDeleteProgress(true)
                    } else {
                        whitelistCollectionViewItem.showProgress(true)
                    }
                }
                return whitelistCollectionViewItem
            }
        } else {
            if itemData?.id ?? "" == Item.ALL_FILTER_LIST_INACTIVE_ITEM_ID {
                let inactiveFilterListItemView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "InactiveFilterListTableCellView"), owner: self)
                return inactiveFilterListItemView
            } else {
                FilterListManager.shared.fetchAndUpdate(item: itemData)
                if itemData?.id ?? "" == Constants.ADS_FILTER_LIST_ID  {
                    adsEnabled = itemData?.active ?? false
                }
                
                let filterListItemView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FilterListTableCellView"), owner: self)
                guard let filterListTableViewItem = filterListItemView as? FilterListTableCellView else { return filterListItemView }
                
                filterListTableViewItem.update(itemData, delegate: self, adsEnabled: adsEnabled)
                
                if currentProcessingItemId == itemData?.id, AssetsManager.shared.status.get() != .idle {
                    filterListTableViewItem.showProgress(true)
                } else {
                    filterListTableViewItem.showProgress(false)
                }
                
                return filterListTableViewItem
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}

extension SectionDetailVC : FilterListTableCellViewDelegate {
    
    func filterListTableCellView(_ cell: FilterListTableCellView, enabledItem item: Item?) {
        guard FilterListManager.shared.canEnable(filterListId: item?.id ?? "DUMMY") else {
            delegate?.onTooManyRulesActiveError()
            cell.checkbox.state = .off
            item?.active = false
            return
        }
        
        currentProcessingItemId = item?.id
        if item?.id ?? "" == Constants.ALLOW_ADS_FILTER_LIST_ID {
            FilterListManager.shared.enable(filterListId: Constants.ADS_FILTER_LIST_ID)
            let adsFilterListItem = items?.filter({ (i) -> Bool in
                return i.id == Constants.ADS_FILTER_LIST_ID
            }).first
            adsFilterListItem?.active = true
        }
        
        item?.active = true
        FilterListManager.shared.enable(filterListId: item?.id ?? "DUMMY")
        FilterListManager.shared.saveState(item: item)
        FilterListManager.shared.callAssetMerge()
    }
    
    func filterListTableCellView(_ cell: FilterListTableCellView, disabledItem item: Item?) {
        currentProcessingItemId = item?.id
        if item?.id ?? "" == Constants.ADS_FILTER_LIST_ID {
            FilterListManager.shared.disable(filterListId: Constants.ALLOW_ADS_FILTER_LIST_ID)
            let allowAdsFilterListItem = items?.filter({ (i) -> Bool in
                return i.id == Constants.ALLOW_ADS_FILTER_LIST_ID
            }).first
            allowAdsFilterListItem?.active = false
        }
        
        item?.active = false
        FilterListManager.shared.disable(filterListId: item?.id ?? "DUMMY")
        FilterListManager.shared.saveState(item: item)
        FilterListManager.shared.callAssetMerge()
    }
}

extension SectionDetailVC: WhitelistTableCellViewDelegate {
    func whitelistTableCellView(_ cell: WhitelistTableCellView, deleteItem item: Item?) {
        guard let url = item?.id else { return }
        deletingWhitelistItem = true
        currentProcessingItemId = url
        WhitelistManager.shared.remove(url)
    }
    
    func whitelistTableCellView(_ cell: WhitelistTableCellView, enabledItem item: Item?) {
        guard WhitelistManager.shared.canEnable() else {
            delegate?.onTooManyRulesActiveError()
            cell.checkbox.state = .off
            item?.active = false
            return
        }
        
        guard let url = item?.id else { return }
        currentProcessingItemId = item?.id
        WhitelistManager.shared.enable(url)
    }
    
    func whitelistTableCellView(_ cell: WhitelistTableCellView, disabledItem item: Item?) {
        guard let url = item?.id else { return }
        currentProcessingItemId = item?.id
        WhitelistManager.shared.disable(url)
    }
}
