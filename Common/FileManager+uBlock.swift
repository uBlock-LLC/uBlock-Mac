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
import SwiftyBeaver

extension FileManager {    
    
    func readJsonFile<T>(at fileUrl: URL?) -> T? {
        guard fileExists(atPath: (fileUrl?.path)!) else { return nil }
        do {
            let fileData = try Data(contentsOf: fileUrl!)
            return try JSONSerialization.jsonObject(with: fileData, options: .allowFragments) as? T
        } catch {
            SwiftyBeaver.error("[ERR_READ_JSON]: \(error), Path: \(fileUrl?.path ?? "NULL")")
            return nil
        }
    }
    
    func writeJsonFile<T>(at fileUrl: URL?, with data: T?) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data ?? [], options: JSONSerialization.WritingOptions.prettyPrinted)
            if FileManager.default.createFile(atPath: (fileUrl?.path)!, contents: jsonData, attributes: nil) {
            } else {
                SwiftyBeaver.error("[ERR_WRITE_JSON_FILE]: Unable to write to file: \(fileUrl?.path ?? "NULL")")
            }
        } catch {
            SwiftyBeaver.error("[ERR_WRITE_JSON_FILE]: \(error), Path = \(fileUrl?.path ?? "NULL")")
        }
    }
    
    
    /// Create directory if not exists
    ///
    /// - Parameters:
    ///   - url: directory url
    ///   - hasIntermediateDir: true to create intermediate directories, false otherwise
    public func createDirectoryIfNotExists(_ url: URL?, withIntermediateDirectories hasIntermediateDir: Bool) {
        if !FileManager.default.fileExists(atPath: (url?.path)!) {
            do {
                try FileManager.default.createDirectory(at: url!, withIntermediateDirectories: hasIntermediateDir, attributes: nil)
                SwiftyBeaver.debug("[CREATE_DIRECTORY]: \(url?.path ?? "NULL")")
            } catch {
                SwiftyBeaver.error("[ERR_CREATE_DIRECTORY]: \(error), Path:\(url?.path ?? "NULL")")
            }
        }
    }
}
