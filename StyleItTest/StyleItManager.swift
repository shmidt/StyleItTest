//
//  StyleItManager.swift
//  StyleItTest
//
//  Created by Dmitry Shmidt on 7/17/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper
import AlamofireObjectMapper
import RealmSwift
import SwiftyJSON
import SVProgressHUD

//To retrieve user's boards, call the following HTTP API (it is an HTTP GET):
//https://test.flaunt.peekabuy.com/api/v2/get_boards/?username=xi-liu1&requester_username=xi-liu1

//To retrieve all styles in a board, call the following HTTP API (also GET):
//https://test.flaunt.peekabuy.com/api/v2/get_board_objects/?username=xi-liu1&requester_username=xi-liu1&board_id=859197&offset=0

//4) User can use camera to upload a new style, the API is as follows:
//https://test.flaunt.peekabuy.com/api/upload_my_style/
//This is a multi-part/form POST request with the following params: username and image (for image data, only JPEG and PNG are supported).
//
//After that, another API call to save the object to a board,
//https://test.flaunt.peekabuy.com/api/save_object_to_board/
//This is a POST request with the following params: username, board_id, and object_id (object_id will be the returned id from previous API call prepended with letter 'l').

extension Alamofire.Request {
    class func imageResponseSerializer() -> Serializer {
        return { request, response, data in
            if data == nil {
                return (nil, nil)
            }
            
            let image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
            
            return (image, nil)
        }
    }
    
    func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(serializer: Request.imageResponseSerializer(), completionHandler: { (request, response, image, error) in
            completionHandler(request, response, image as? UIImage, error)
        })
    }
}

public let StyleItUser = (
    Username: "xi-liu1",
    RequesterUsername: "xi-liu1")

public let StyleItManagerSingleton = StyleItManager()

public class StyleItManager {
    let formatter = NSByteCountFormatter()
    
    public typealias BoardsCompletion = (boards: [Board]?, error: NSError?) -> Void
    public typealias StylesCompletion = (styles: [Style]?, error: NSError?) -> Void
    
    let baseUrl = "https://test.flaunt.peekabuy.com/api/"
    
    public init() {}
    
    //MARK: - Common methods for tests and app
    public func createOrUpdateBoardsInRealm(realm: Realm, withJSONData jsonData: AnyObject, completion: BoardsCompletion) {
        let json = JSON(jsonData)

        let entries = json["boards"]
        var boards = [Board]()
        
        realm.write {
            for (index: String, subJson : JSON) in entries {

                if let entry = Mapper<Board>().map(subJson.dictionaryObject){
                    
                    let queryRecordID = realm.objects(Board).filter("id == '\(entry.id)'")
                    
                    if queryRecordID.count == 0{
                        
                        //First time adding
                        realm.add(entry, update: false)
                        boards.append(entry)
                        
                    }else{
                        let recordEntry = queryRecordID.first
                        recordEntry?.thumnailHeight = entry.thumnailHeight
                        recordEntry?.thumnailWidth = entry.thumnailWidth
                        recordEntry?.thumnailUrlAddress = entry.thumnailUrlAddress
                    }
                }
            }
        }

        completion(boards: boards, error: nil)
    }
    
    public func createOrUpdateStylesInRealm(realm: Realm, forBoard board: Board, withJSONData jsonData: AnyObject, completion: StylesCompletion?) {
        let json = JSON(jsonData)

        let entries = json["objects"]
        var styles = [Style]()
        realm.write {
            let realm = Realm()
            
            for (index: String, subJson : JSON) in entries {
                
                if let entry = Mapper<Style>().map(subJson["look"].dictionaryObject){
                    
                    let queryRecordID = realm.objects(Style).filter("id == '\(entry.id)'")
                    
                    if queryRecordID.count == 0{
                        
                        //First time adding
                        entry.board = board
                        realm.add(entry, update: true)
                        styles.append(entry)
                        
                    }else{
                        
                        //Updating
                        let recordEntry = queryRecordID.first
                        recordEntry?.thumnailHeight = entry.thumnailHeight
                        recordEntry?.thumnailWidth = entry.thumnailWidth
                        recordEntry?.thumnailUrlAddress = entry.thumnailUrlAddress
                    }
 
                }else{
                    println("JSON came corrupted or JSON version was changed")
                    self.showError("There are some problems on the server.", error: nil)
                }
            }
            
        }
        if let completion = completion{
            completion(styles: styles, error: nil)
        }
    }

    //MARK: - App methods
    func updateBoardsFromServer(completion: BoardsCompletion){
        
        let parameters = [
            "username": StyleItUser.Username,
            "requester_username": StyleItUser.RequesterUsername]

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        SVProgressHUD.showWithStatus("Updating boards, please wait.")
        
        Alamofire.request(.GET, baseUrl + "v2/get_boards/", parameters: parameters).responseJSON(options: NSJSONReadingOptions.AllowFragments) { [unowned self] (request, response, responseObject, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            SVProgressHUD.dismiss()

            if let data: AnyObject = responseObject{

                let realm = Realm()
                self.createOrUpdateBoardsInRealm(realm, withJSONData: data, completion: completion)
            }else{
                completion(boards: nil, error: error)
                if let error = error{
                    self.showError("Error updating styles", error: error)
                }
            }
        }
    }
    
    func updateStylesForBoard(board: Board, page: Int, completion: StylesCompletion) -> Alamofire.Request{
        
        let parameters = [
            "username": StyleItUser.Username,
            "requester_username": StyleItUser.RequesterUsername,
            "board_id": "\(board.id)",
            "offset": "\(page)"
        ]
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        return Alamofire.request(.GET, baseUrl + "v2/get_board_objects/", parameters: parameters).responseJSON(options: NSJSONReadingOptions.AllowFragments) { [unowned self] (request, response, responseObject, error) -> Void in

            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
            if let data: AnyObject = responseObject{
                
                let realm = Realm()
                self.createOrUpdateStylesInRealm(realm, forBoard: board, withJSONData: data, completion: completion)
            }else{
                completion(styles: nil, error: error)
                if let error = error{
                    self.showError("Error updating styles", error: error)
                }
                
                
            }
            
        }
    }
    public typealias UploadCompletion = (success: Bool) -> Void
    public func uploadStyleForBoard(board: Board, image: UIImage, completion: UploadCompletion) {
        
        let fileUploader = FileUploader()
        
        fileUploader.addFileData( UIImageJPEGRepresentation(image, 0.8), withName: "image", withMimeType: "image/jpeg" )

        fileUploader.setValue( StyleItUser.Username, forParameter: "username" )
        
        // put your server URL here
        var request = NSMutableURLRequest( URL: NSURL(string: baseUrl + "upload_my_style/" )! )
        request.HTTPMethod = "POST"
        if let alamoRequest = fileUploader.uploadFile(request: request){
        alamoRequest.progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in

            dispatch_async(dispatch_get_main_queue()) {
                let totalBytesWrittenText = self.formatter.stringFromByteCount(Int64(totalBytesWritten))
                let totalBytesExpectedToWriteText = self.formatter.stringFromByteCount(Int64(totalBytesExpectedToWrite))
                let progress = Float(totalBytesWritten / totalBytesExpectedToWrite)
                SVProgressHUD.showProgress(progress, status: "Uploading \(totalBytesWrittenText) / \(totalBytesExpectedToWriteText)", maskType: SVProgressHUDMaskType.Gradient)
            }
        }.responseJSON { (request, response, responseObject, error) in
            SVProgressHUD.dismiss()
            if let error = error{
                
                self.showError("Error updating styles", error: error)
                
            }
            if let responseObject: AnyObject = responseObject{
                let json = JSON(responseObject)
                if let objID = json["inspiration_look"]["id"].string{
                    println("Style ID is \(objID)")
                    self.saveStyleForBoard(board, styleID: objID, completion: completion)
                    
                }
            }
            }
        }
    }

    private func saveStyleForBoard(board: Board, styleID: String, completion: UploadCompletion) -> Alamofire.Request{
        
        let parameters = [
            "username": StyleItUser.Username,
            "board_id": board.id,
            "object_id": "l" + "\(styleID)"
        ]
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        return Alamofire.request(.POST, baseUrl + "save_object_to_board/", parameters: parameters).responseJSON(options: NSJSONReadingOptions.AllowFragments) { [unowned self] (request, response, responseObject, error) -> Void in

            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if let error = error{
                
                let realm = Realm()
                self.showError("Sorry, \nstyle not saved", error: error)
            }else{
                
                SVProgressHUD.showSuccessWithStatus("Style saved successfully")
                
            }
            
        }
    }
    
    //MARK: - Utilities
    func showError(title: String, error: NSError? = nil){
        if error?.code == -999 || error?.code == -1009{
            //1. We cancelled it, so there is no error
            //2. Offline mode
            return
        }
        let alertController = UIAlertController(title: title, message: error?.localizedDescription, preferredStyle: .Alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .Cancel) { (action) in }
        alertController.addAction(OKAction)
        
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true) {}
    }
    
}

