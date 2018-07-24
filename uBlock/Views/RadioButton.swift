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

@IBDesignable
class RadioButton: Button {
    
    @IBInspectable var normalTitleColor: NSColor?
    @IBInspectable var selectedTitleColor: NSColor?
    
    @IBInspectable var normalBackgroundColor: NSColor?
    @IBInspectable var selectedBackgroundColor: NSColor?
    
    override func awakeFromNib() {
        self.wantsLayer = true
        self.updateState(self.state)        
    }
    
    override var state: NSControl.StateValue {
        didSet {
            self.updateState(state)
        }
    }
    
    private func updateState(_ state: NSControl.StateValue) {
        if state == .on {
            deselectOthers()
            if let selectedTitleColor = self.selectedTitleColor {
                self.textColor = selectedTitleColor
            }
            if let selectedBackgroundColor = self.selectedBackgroundColor {
                animateSelectionChange(with: selectedBackgroundColor)
            }
        } else {
            if let normalTitleColor = self.normalTitleColor {
                self.textColor = normalTitleColor
            }

            if let normalBackgroundColor = self.normalBackgroundColor {
                animateSelectionChange(with: normalBackgroundColor, duration: 0.01)
            }
        }
    }
    
    private func animateSelectionChange(with backgroundColor: NSColor?, duration: CFTimeInterval = 0.2) {
        self.layer?.removeAllAnimations()
        let anim = CABasicAnimation(keyPath: "backgroundColor")
        anim.fromValue = self.layer?.backgroundColor
        anim.toValue = backgroundColor?.cgColor
        anim.duration = duration
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        self.layer?.add(anim, forKey: "backgroundColor")
    }
    
    private func deselectOthers() {
        for view in self.superview?.subviews ?? [] {
            guard let radioButton = view as? RadioButton, radioButton != self else { continue }
            radioButton.state = .off
        }
    }
}
