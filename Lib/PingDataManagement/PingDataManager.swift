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
import Alamofire
import SafariServices

class PingDataManager: NSObject {
    static let shared: PingDataManager = PingDataManager()
    
    private override init() {}
    
    func start() {
        if UserPref.lastPingDate() == nil {
            UserPref.setLastPingDate(Date())
        }
        schedulePingData()
    }
    
    func sendPingIfDatePassed() {
        guard shouldSendPingData() else {
            return
        }
        
        let pingDate = nextScheduleDate()
        let currentDate = Date()
        if currentDate >= pingDate {
            sendPingData()
        }
    }
    
    private func schedulePingData() {
        sendPingIfDatePassed()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + (60 * 60)) {
            self.schedulePingData()
        }
    }
    
    private func sendPingData() {
        UserPref.incrementTotalPings()
        guard let url = URL(string: "\(Constants.API_URL)\(Constants.Api.pingData)" ) else {
            return
        }
        let pingData = preparePingData()
        SwiftyBeaver.debug("[PING_DATA_REQUEST]: \(url.absoluteString) => Para: \(pingData)")
        Alamofire.request(url, method: .post, parameters: pingData)
            .validate()
            .response { (response) in
                guard let data = response.data else {
                    SwiftyBeaver.error("Error in sending ping data: \(String(describing: response.error))")
                    return
                }
                SwiftyBeaver.debug("[PING_DATA_RESPONSE]: \(String(data: data, encoding: .utf8) ?? "")")
                UserPref.setLastPingDate(Date())
        }
    }
    
    private func preparePingData() -> [String: Any] {
        var pingData: [String: Any] = [:]
        
        pingData["n"] = "uBlock Mac App" //Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        pingData["v"] = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        pingData["b"] = 0   // blocked ads count
        pingData["a"] = 0   // allowed ads count
        pingData["ad"] = 0  // advance user enabled or not
        pingData["df"] = 0  // dynamic filters enabled or not
        pingData["u"] = generateOrGetUserId()   // user id
        pingData["o"] = UserPref.operatingSystem()  // operating system
        pingData["ov"] = UserPref.operatingSystemVersion() // operating system version
        pingData["f"] = "MA" // browser flavor
        pingData["bv"] = UserPref.safariVersion()   // browser version
        pingData["l"] = UserPref.safariLanguage()   // browser language
        pingData["aa"] = FilterListManager.shared.isEnabled(filterListId: Constants.ALLOW_ADS_FILTER_LIST_ID) ? 1 : 0
        
        return pingData
    }
    
    private func generateOrGetUserId() -> String {
        if let userId = UserPref.userId() {
            return userId
        }
        let newUserId = NSUUID().uuidString
        UserPref.setUserId(newUserId)
        return newUserId
    }
    
    private func nextScheduleDate() -> Date {
        let totalPings = UserPref.totalPings()
        var delayHours = 1
        if totalPings == 0 {
            delayHours = 1
        } else if totalPings < 8 {
            delayHours = 24
        } else {
            delayHours = 24 * 7
        }
        
        let lastPingDate = UserPref.lastPingDate() ?? Date()
        return lastPingDate + TimeInterval(60 * 60 * delayHours)
    }
    
    private func shouldSendPingData() -> Bool {
        let totalPings = UserPref.totalPings()
        if totalPings > 5000 {
            if totalPings > 5000 && totalPings < 100000 && ((totalPings % 5000) != 0) {
                return false
            }
            
            if totalPings >= 100000 && ((totalPings % 50000) != 0) {
                return false
            }
        }
        
        return true
    }
}
