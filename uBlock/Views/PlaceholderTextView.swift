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

class PlaceholderTextView: NSTextView {
    private var placeholderAttributeString: NSAttributedString?
    private let placeholderDrawingPoint = NSPoint(x: 6, y: 0)
    private let placeholderAttributes: [NSAttributedStringKey: Any]? = [NSAttributedStringKey.foregroundColor: NSColor.gray]
    
    func setPlaceholderText(_ text: String) {
        placeholderAttributeString = NSAttributedString(string: text, attributes: placeholderAttributes)
        displayIfNeeded()
    }
    
    override func becomeFirstResponder() -> Bool {
        displayIfNeeded()
        return super.becomeFirstResponder()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if self.string.count == 0 {
            placeholderAttributeString?.draw(at: placeholderDrawingPoint)
        }
    }
    
    override func resignFirstResponder() -> Bool {
        displayIfNeeded()
        return super.resignFirstResponder()
    }
    
}
