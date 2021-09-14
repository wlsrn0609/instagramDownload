//
//  FindString.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import Foundation

extension String {
    func findString(from:String, to:String, lastIndex kLastIndex:Index? = nil, strings kStrings: [String], complete:(([String]) -> Void)) {
        
        var lastIndex = kLastIndex ?? startIndex
        var findStrings = kStrings
        
        if let findString = (range(of: from, range: lastIndex..<endIndex)?.upperBound).flatMap({ substringFrom -> String? in
            return (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo -> String in
                lastIndex = substringTo
                return String(self[substringFrom..<substringTo])
            }
        }) {
//            print("findString:\(findString)")
            findStrings.append(findString)
            if lastIndex < endIndex {
                self.findString(from: from, to: to, lastIndex: lastIndex, strings: findStrings, complete: complete)
                return
            }
        }
        complete(findStrings)
    }
}
