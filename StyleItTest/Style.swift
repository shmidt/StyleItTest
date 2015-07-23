//
//  Style.swift
//  StyleItTest
//
//  Created by Dmitry Shmidt on 7/17/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper

public class Style: Thumbnail {
    dynamic var board: Board?
    required convenience public init?(_ map: Map) {
        self.init()
        mapping(map)
    }
    
}

extension Style : Mappable {
    
    public func mapping(map: Map) {
        id <- map["id"]
        thumnailUrlAddress <- map["thumbnail_url"]
        thumnailHeight <- map["thumbnail_height"]
        thumnailWidth <- map["thumbnail_width"]
    }
}
