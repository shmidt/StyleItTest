//
//  Board.swift
//  StyleItTest
//
//  Created by Dmitry Shmidt on 7/17/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.
//

import UIKit
import RealmSwift
import ObjectMapper

public class Board: Thumbnail {
    
    required convenience public init?(_ map: Map) {
        self.init()
        mapping(map)
    }
}

 extension Board : Mappable {
    
    public func mapping(map: Map) {

        let transform = TransformOf<String, Int>(fromJSON: { (value: Int?) -> String? in
            // transform value from Int? to String?
            if let value = value {
                return String(value)
            }
            return nil
            }, toJSON: { (value: String?) -> Int? in
                // transform value from String? to Int?
                return value?.toInt()
        })
        
        id <- (map["board_id"], transform)
        thumnailUrlAddress <- map["thumbnail_url"]
        thumnailHeight <- map["thumbnail_height"]
        thumnailWidth <- map["thumbnail_width"]
    }
}