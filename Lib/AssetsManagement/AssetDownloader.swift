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
import Alamofire
import SwiftyBeaver

enum AssetDownloaderStatus {
    case idle
    case downloading
    case completed
    case downloadError
}

class AssetDownloader: NSObject {
    static let shared: AssetDownloader = AssetDownloader()
    
    var status: AssetDownloaderStatus = .idle
    
    private override init() {}
    
    
    /// Initiate the assets downloader
    func start(_ completion: ((AssetDownloaderStatus) -> Void)? = nil) {
        if self.status != .idle {
            return
        }
        
        self.status = .downloading
        self.fetchChecksums { (checksums) in
            guard let checksums = checksums, checksums.count > 0 else {
                self.status = .downloadError
                completion?(.downloadError)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    self.status = .idle
                })
                return
            }
            let updatedChecksums = self.findUpdatedChecksums(checksums)
            SwiftyBeaver.debug("[UPDATED_CHECKSUMS]: \(updatedChecksums ?? [:])")
            
            self.beginDownloadV2(updatedChecksums) { (error) in
                if let _ = error {
                    self.status = .downloadError
                    completion?(.downloadError)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        self.status = .idle
                    })
                    return
                }
                self.status = .completed
                self.updateChecksum(checksums)
                completion?(.completed)
                self.status = .idle
            }
        }
    }
    
    /// Fetch the checksums data of assets from server
    ///
    /// - Parameter completion: completion handler
    private func fetchChecksums(_ completion: @escaping ([String: String]?) -> Void) {
        guard let url = URL(string: "\(Constants.API_URL)\(Constants.Api.checksum)" ) else {
            completion(nil)
            return
        }
        SwiftyBeaver.debug("[CHECKSUM_REQUEST]: \(url.absoluteString)")
        Alamofire.request(url)
            .validate()
            .responseJSON { (response) in
                guard response.result.isSuccess else {
                    SwiftyBeaver.error("Error while fetching checksum: \(String(describing: response.result.error))")
                    completion(nil)
                    return
                }
                SwiftyBeaver.debug("[CHECKSUM_RESPONSE]: \(String(data: response.data!, encoding: .utf8) ?? "")")
                completion(response.result.value as? [String: String])
            }
    }
    
    
    /// Update checksum data locally
    ///
    /// - Parameter checksum: checksum data
    private func updateChecksum(_ checksums: [String: String]?) {
        let assetsDirUrl = Constants.AssetsUrls.assetsFolder
        FileManager.default.createDirectoryIfNotExists(assetsDirUrl, withIntermediateDirectories: true)
        
        let checksumsFileUrl = Constants.AssetsUrls.assetsChecksumUrl
        SwiftyBeaver.debug("[CHECKSUMS_FILE_PATH]: \(checksumsFileUrl?.path ?? "NULL")")
        do {
            let checksumsData = try JSONSerialization.data(withJSONObject: checksums ?? [:], options: JSONSerialization.WritingOptions.prettyPrinted)
            if FileManager.default.createFile(atPath: (checksumsFileUrl?.path)!, contents: checksumsData, attributes: nil) {
                SwiftyBeaver.debug("[UPDATE_CHECKSUMS]: Successful")
            } else {
                SwiftyBeaver.error("[ERR_UPDATE_CHECKSUMS]: Unable to write checksums to file")
            }
        } catch {
            SwiftyBeaver.error("[ERR_UPDATE_CHECKSUMS]: \(error)")
        }
    }
    
    
    /// Find updated checksums by comparing with locally stored checksums
    ///
    /// - Parameter checksums: checksums from server
    /// - Returns: updated or empty checksums
    private func findUpdatedChecksums(_ checksums: [String: String]?) -> [String: String]? {
        let localChecksums: [String: String]? = FileManager.default.readJsonFile(at: Constants.AssetsUrls.assetsChecksumUrl)
        let updatedChecksums = checksums?.filter({ (key,val) -> Bool in
            return localChecksums?[key] != val
        })
        return updatedChecksums
    }
    
    /// Way 1
    /// Initiate downloading of filter lists and recursively download it
    ///
    /// - Parameters:
    ///   - checksums: updated checksums data
    ///   - completion: completion handler
    /*private func beginDownload(_ checksums: [String: String]?, completion: @escaping ()->Void) {
        guard checksums?.count ?? 0 > 0 else {
            SwiftyBeaver.debug("[BEGIN_DOWNLOAD]: Nothing to download...")
            completion()
            return
        }
        
        let keys = Array((checksums?.keys)!)
        func beginDownloadRecursive(_ index: Int) {
            if index >= keys.count {
                SwiftyBeaver.debug("[BEGIN_DOWNLOAD]: Assets downloaded...")
                completion()
                return
            }
            
            SwiftyBeaver.debug("[BEGIN_DOWNLOAD]: Initiate download... \(keys[index]) [\(index+1) / \(keys.count)]")
            self.download(keys[index]) {
                beginDownloadRecursive(index + 1)
            }
        }
        
        beginDownloadRecursive(0)
    }*/
    
    /// Way 2
    /// Initiate downloading of filter lists and recursively download it
    ///
    /// - Parameters:
    ///   - checksums: updated checksums data
    ///   - completion: completion handler
    private func beginDownloadV2(_ checksums: [String: String]?, completion: @escaping (Error?)->Void) {
        guard let checksums = checksums else {
            SwiftyBeaver.debug("[BEGIN_DOWNLOAD]: Nothing to download...")
            completion(nil)
            return
        }
        
        let checksumDownloadGroup = DispatchGroup()
        var idx = 0
        let total = checksums.count
        var storedError: Error? = nil
        for (key, _) in checksums {
            checksumDownloadGroup.enter()
            idx = idx + 1
            SwiftyBeaver.debug("[BEGIN_DOWNLOAD]: Initiate download... \(key) [\(idx) / \(total)]")
            self.download(key, completion: { (error, data) in
                if let error = error {
                    storedError = error
                } else {
                    // Save filterlist data to json file
                    let thirdPartyDirUrl = Constants.AssetsUrls.thirdPartyFolder
                    FileManager.default.createDirectoryIfNotExists(thirdPartyDirUrl, withIntermediateDirectories: true)
                    
                    let filterListFileUrl = thirdPartyDirUrl?.appendingPathComponent("\(key).json")
                    SwiftyBeaver.debug("[FILTERLIST_FILE_PATH]: \(filterListFileUrl?.path ?? "NULL")")
                    if FileManager.default.createFile(atPath: (filterListFileUrl?.path)!, contents: data, attributes: nil) {
                        SwiftyBeaver.debug("[UPDATE_FILTERLIST]: Successful")
                    } else {
                        SwiftyBeaver.error("[ERR_UPDATE_FILTERLIST]: Unable to write checksums to file")
                    }
                }
                
                checksumDownloadGroup.leave()
            })
        }
        checksumDownloadGroup.notify(queue: .main) {
            SwiftyBeaver.debug("[BEGIN_DOWNLOAD]: Assets downloaded...")
            completion(storedError)
        }
    }
    
    /// Download filter list by id provided in checksums and save it in shared group directory of app
    ///
    /// - Parameters:
    ///   - filterListId: filter list id
    ///   - completion: completion handler
    private func download(_ filterListId: String, completion: @escaping (Error?, Data?) -> Void) {
        SwiftyBeaver.debug("[DOWNLOAD]: Downloading... \(filterListId)")
        guard let url = URL(string: "\(Constants.API_URL)\(Constants.Api.filterlist)/\(filterListId)" ) else {
            completion(Constants.uBlockError.invalidApiUrl, nil)
            return
        }
        
        SwiftyBeaver.debug("[DOWNLOAD_REQUEST]: \(url.absoluteString)")
        Alamofire.request(url)
            .validate()
            .responseJSON { (response) in
                guard response.result.isSuccess else {
                    SwiftyBeaver.error("Error while downloading filterlist: \(String(describing: response.result.error))")
                    completion(response.result.error, nil)
                    return
                }
                
                let bcf = ByteCountFormatter()
                bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
                bcf.countStyle = .file
                let filterDataSize = bcf.string(fromByteCount: Int64(response.data?.count ?? 0))
                SwiftyBeaver.debug("[DOWNLOAD]: Downloaded... \(filterListId) (\(filterDataSize))")
                completion(nil, response.data)
        }
    }
}
