//
//  FindString.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import Foundation

extension String {
    func findString(from:String, to:String, lastIndex kLastIndex:Index? = nil, strings kStrings: [String], complete:(([String]) -> Void)) {
        //todo 못찾아도 complete가 일어나는지 확인이 필요하다
        var lastIndex = kLastIndex ?? startIndex
        var findStrings = kStrings
        
        if let findString = (range(of: from, range: lastIndex..<endIndex)?.upperBound).flatMap({ substringFrom -> String? in
            return (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo -> String in
                lastIndex = substringTo
                return String(self[substringFrom..<substringTo])
            }
        }) {
            print("findString:\(findString)")
            findStrings.append(findString)
            if lastIndex < endIndex {
                self.findString(from: from, to: to, lastIndex: lastIndex, strings: findStrings, complete: complete)
                return
            }
        }
//        print("findString complete")
        complete(findStrings)
    }
}

var sampleString = """
    srcset="https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s640x640/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=90f4c8516425e2225712f35bcff61b8e&amp;oe=6147ACA5&amp;_nc_sid=83d603 640w,https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s750x750/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=37e76a35eadf93bb642468b66486ecd8&amp;oe=61480C65&amp;_nc_sid=83d603 750w,https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/e35/241700777_929174931062470_961596759477656433_n.jpg?se=7&amp;_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=2dde210b914d341bc0f3420a34332ea7&amp;oe=61480602&amp;_nc_sid=83d603 1080w" src="https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/e35/241700777_929174931062470_961596759477656433_n.jpg?se=7&amp;_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=2dde210b914d341bc0f3420a34332ea7&amp;oe=61480602&amp;_nc_sid=83d603"
    """
/*
https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s640x640/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=90f4c8516425e2225712f35bcff61b8e&amp;oe=6147ACA5&amp;_nc_sid=83d603 640w,https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s750x750/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=37e76a35eadf93bb642468b66486ecd8&amp;oe=61480C65&amp;_nc_sid=83d603 750w,https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/e35/241700777_929174931062470_961596759477656433_n.jpg?se=7&amp;_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=2dde210b914d341bc0f3420a34332ea7&amp;oe=61480602&amp;_nc_sid=83d603 1080w

https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s640x640/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&amp;_nc_cat=1&amp;_nc_ohc=ED6Ul3JjqvUAX___f1S&amp;tn=NsH84sLPnmKyXZoU&amp;edm=AABBvjUBAAAA&amp;ccb=7-4&amp;oh=90f4c8516425e2225712f35bcff61b8e&amp;oe=6147ACA5&amp;_nc_sid=83d603

https://scontent-gmp1-1.cdninstagram.com/v/t51.2885-15/sh0.08/e35/s640x640/241700777_929174931062470_961596759477656433_n.jpg?_nc_ht=scontent-gmp1-1.cdninstagram.com&_nc_cat=1&_nc_ohc=ED6Ul3JjqvUAX___f1S&tn=NsH84sLPnmKyXZoU&edm=AABBvjUBAAAA&ccb=7-4&oh=90f4c8516425e2225712f35bcff61b8e&oe=6147ACA5&_nc_sid=83d603
*/
