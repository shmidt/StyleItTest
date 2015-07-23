//
//  Thumbnail.swift
//  StyleItTest
//
//  Created by Dmitry Shmidt on 7/19/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.
//

import UIKit
import RealmSwift

public class Thumbnail: Object {
    
    dynamic var id = ""
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    dynamic var thumnailHeight = 0
    dynamic var thumnailWidth = 0
    dynamic var thumnailUrlAddress = ""
    
    dynamic var thumbnailData = NSData()
    
    var thumbnailUrl: NSURL?{
        return NSURL(string: thumnailUrlAddress)
    }
    
    var thumbnail: UIImage?{
        get{
            return thumbnailData == NSData() ? nil : UIImage(data: thumbnailData)
        }
        set(newThumbnail){
            
            if let thumb = newThumbnail{
                thumbnailData = UIImageJPEGRepresentation(thumb, 0.8)
            }else {
                thumbnailData = NSData()
            }
            
        }
    }

    override public static func ignoredProperties() -> [String] {
        return ["thumbnail"]
    }
    
    var aspectRatio: CGFloat{
        return (UIScreen.mainScreen().bounds.size.width) / CGFloat(thumnailWidth)
    }
    
    var size: CGSize{
        let height = CGFloat(thumnailHeight)
        let width = CGFloat(thumnailWidth)
        
        return CGSize(width: width, height: height)
    }
}
