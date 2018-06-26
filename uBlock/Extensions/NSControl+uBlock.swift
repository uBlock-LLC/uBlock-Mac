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

extension NSControl {
    
    @IBInspectable
    var useLucidaGrandeRegularFont: Bool {
        set(value) {
            if value {
                self.font = NSFont(name: "LucidaGrande", size: self.font?.pointSize ?? 12)
            }
        }
        get {
            return false
        }
    }
    
    @IBInspectable
    var useLucidaGrandeBoldFont: Bool {
        set(value) {
            if value {
                self.font = NSFont(name: "LucidaGrande-Bold", size: self.font?.pointSize ?? 12)
            }
        }
        get {
            return false
        }
    }
    
    @IBInspectable
    var textLineHeightMultiplier: CGFloat {
        set(value) {
            let textParagraph:NSMutableParagraphStyle = NSMutableParagraphStyle()
            textParagraph.lineHeightMultiple = value
            self.attributedStringValue = NSAttributedString(string: self.stringValue, attributes: [.paragraphStyle : textParagraph])
        }
        get {
            return 1
        }
    }
    
    @IBInspectable
    var borderColor: NSColor? {
        set(value) {
            self.wantsLayer = true
            self.layer?.borderColor = value?.cgColor
        }
        get {
            return NSColor(cgColor: self.layer?.borderColor ?? NSColor.black.cgColor)
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        set(value) {
            self.wantsLayer = true
            self.layer?.borderWidth = value
        }
        get {
            return self.layer?.borderWidth ?? 0
        }
    }
    
    @IBInspectable
    var cornerRadius: CGFloat {
        set(value) {
            self.wantsLayer = true
            self.layer?.cornerRadius = value
        }
        get {
            return self.layer?.cornerRadius ?? 0
        }
    }
    
    
}
