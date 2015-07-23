//
//  ThumbnailCell.swift
//  StyleItTest
//
//  Created by Dmitry Shmidt on 7/17/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.
//

import UIKit
import Alamofire

class ThumbnailCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndidcator: UIActivityIndicatorView!
    
    // request stored for cancellation and checking the original URLString
    var request: Alamofire.Request?
    
    @IBOutlet weak var imageView: UIImageView!
    
    func downloadImage(url: NSURL, completion: (image: UIImage)->Void){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        activityIndidcator.startAnimating()
        
        imageView.image = nil
        
        request = Alamofire.request(.GET, url).validate(contentType: ["image/*"]).responseImage() {[weak self]
            (request, _, image, error) in
            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndidcator.stopAnimating()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                if error == nil && image != nil {
                    self?.imageView.image = image
                    completion(image: image!)
                } else {
                    
                }
            }
        }
        
    }
}
