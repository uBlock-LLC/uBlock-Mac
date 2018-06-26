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

//let url = "www.xyz.com"
//let idx = url.range(of: "://")

private func removeProtocol(from url: String) -> String {
    let dividerRange = url.range(of: "://")
    guard let divide = dividerRange?.upperBound else { return url }
    //let path = url.substring(from: divide)
    let path = String(url[divide...])
    return path
}

func normalizeUrl(_ url: String) -> String {
    var normalizedUrl = removeProtocol(from: url)
    guard let firstSlashIndex = normalizedUrl.index(of: "/") else {
        return normalizedUrl
    }
    normalizedUrl = String(normalizedUrl[..<firstSlashIndex])
    
    return normalizedUrl
}

/*print(normalizeUrl("https://www.cricheroes.in/tournament/12795/Vimal-Cup-U-19-Cricket-Tournament-2018/?q=test"))
print(normalizeUrl("*.theguardian.co/index.html"))
print(normalizeUrl("in.theguardian.com/index.html"))*/

func isValid(url: String) -> Bool {
    let trimmedUrl = removeUrlComponentsAfterHost(url: url)
    let urlRegEx = "((?:http|https)://)?(((?:www)?|(?:\\*)?|(?:[a-zA-z0-9]{1,})?)\\.)?[\\w\\d\\-_]+\\.(\\w{2,}?|(\\w{2}--\\w{2,})?)(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
    let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
    let result = urlTest.evaluate(with: trimmedUrl)
    return result
}

func removeUrlComponentsAfterHost(url: String) -> String {
    var host = ""
    var firstSlashRange: Range<String.Index>?
    if let protocolRange = url.range(of: "://") {
        //print(url[..<protocolRange.upperBound])
        let searchRange = Range<String.Index>(uncheckedBounds: (lower: protocolRange.upperBound, upper: url.endIndex))
        //print(url[searchRange])
        firstSlashRange = url.range(of: "/", options: .literal, range: searchRange, locale: Locale.current)
    } else {
        firstSlashRange = url.range(of: "/", options: .literal, range: nil, locale: Locale.current)
    }
    host = String(url[..<(firstSlashRange?.lowerBound ?? url.endIndex)])
    return host
}

print(removeUrlComponentsAfterHost(url: "https://www.cricheroes.in/tournament/12795/Vimal-Cup-U-19-Cricket-Tournament-2018/"))
print(removeUrlComponentsAfterHost(url: "www.cricheroes.in/tournament/12795/Vimal-Cup-U-19-Cricket-Tournament-2018/"))

isValid(url: "theguardian.com")
isValid(url: "http://www.theguardian.com/")
isValid(url: "www.theguardian.co/index.html")
isValid(url: "*.theguardian.co/index.html")
isValid(url: "in.pinterest.com")
isValid(url: "123abcdef123.pinterest.com")
isValid(url: "d.android.com/?q=test")
isValid(url: "*android.com/")
isValid(url: "ftp://www.theguardian.co/index.html")
isValid(url: "https://www.cricheroes.in/tournament/12795/Vimal-Cup-U-19-Cricket-Tournament-2018")
print("-- gTLD --")
isValid(url: "xyz.ninja")
isValid(url: "www.xyz.xn--otu796d")
isValid(url: "https://www.washingtonpost.com/news/politics/wp/2018/05/18/2018-has-been-deadlier-for-schoolchildren-than-service-members/?q=test")
