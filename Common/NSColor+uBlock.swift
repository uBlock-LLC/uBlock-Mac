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

extension NSColor {
    class var sectionHeaderBackgroundColor: NSColor {
        return gray.withAlphaComponent(0.5)
    }
    
    class var sectionItemSelectionBackgroundColor: NSColor {
        return white.withAlphaComponent(0.25)
    }
    
    class var sectionItemNormalBackgroundColor: NSColor {
        return clear
    }
    
    class var sectionItemNormalTextColor: NSColor {
        return black
    }
    
    class var sectionItemSelectionTextColor: NSColor {
        return white
    }
}
