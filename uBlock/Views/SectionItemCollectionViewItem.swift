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

protocol SectionItemCollectionViewItemDelegate {
    func sectionItem(_ item: Item?, didActive active: Bool, at indexPath: IndexPath)
}

class SectionItemCollectionViewItem: NSCollectionViewItem {
    
    fileprivate static let SECTION_ITEM_NORMAL_FONT = NSFont(name: "LucidaGrande", size: 14)!
    fileprivate static let SECTION_ITEM_SELECTED_FONT = NSFont(name: "LucidaGrande-Bold", size: 14)!
    
    @IBOutlet weak var lblTitle: NSTextField!
    
    var delegate: SectionItemCollectionViewItemDelegate? = nil
    
    private var item: Item? = nil
    private var indexPath: IndexPath!
    
    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected ? NSColor.sectionItemSelectionBackgroundColor.cgColor : NSColor.sectionItemNormalBackgroundColor.cgColor
            lblTitle.font = isSelected ? SectionItemCollectionViewItem.SECTION_ITEM_SELECTED_FONT : SectionItemCollectionViewItem.SECTION_ITEM_NORMAL_FONT
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.sectionItemNormalBackgroundColor.cgColor
        lblTitle.font = SectionItemCollectionViewItem.SECTION_ITEM_NORMAL_FONT
    }
    
    func update(_ item: Item?, for indexPath: IndexPath?) {
        self.item = item
        self.indexPath = indexPath
        self.lblTitle.stringValue = item?.name ?? ""
    }
}
