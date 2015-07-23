//
//  RealmTests.swift
//  StyleItTest
//
//  Created by Dmitry Shmidt on 7/17/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.
//

import UIKit
import XCTest
import RealmSwift
import StyleItTest

class RealmTests: XCTestCase {

    let realmPathForTesting = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0].stringByAppendingPathComponent("test")
    
    func deleteRealmFilesAtPath(path: String) {
        let fileManager = NSFileManager.defaultManager()
        fileManager.removeItemAtPath(path, error: nil)
        let lockPath = path + ".lock"
        fileManager.removeItemAtPath(lockPath, error: nil)
    }
    
    func testThatBoardsAreUpdatedFromServer() {
        let path = NSBundle.mainBundle().pathForResource("boards", ofType: "json")!
        let data = NSData(contentsOfFile: path)!
        
        let testRealm = Realm(path: realmPathForTesting)
        
        if let jsonData: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) {

            StyleItManagerSingleton.createOrUpdateBoardsInRealm(testRealm, withJSONData: jsonData, completion: { (boards, error) -> Void in
                XCTAssertNil(error, "Failed to load the boards")
            })
        
           
        } else {
            XCTFail("Failed to load the boards")
        }
    }

    func testThatStylesAreUpdatedFromServer() {
        let path = NSBundle.mainBundle().pathForResource("boards", ofType: "json")!
        let data = NSData(contentsOfFile: path)!
        
        let testRealm = Realm(path: realmPathForTesting)
        
        if let board = testRealm.objects(Board).first{
            if let jsonData: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) {
                
                StyleItManagerSingleton.createOrUpdateStylesInRealm(testRealm, forBoard: board, withJSONData: jsonData, completion: { (styles, error) -> Void in
                    XCTAssertNotNil(styles, "Styles not updated")
                })
            } else {
                XCTFail("Failed to load the styles")
            }
            XCTFail("Failed to get test board")
        }
 
    }
    
    func testStyleUpload(){
        self.measureBlock() {
            // Put the code you want to measure the time of here.
            let testRealm = Realm(path: self.realmPathForTesting)
            
            if let board = testRealm.objects(Board).first{
            if let image = UIImage(named: "image.jpg"){
                StyleItManagerSingleton.uploadStyleForBoard(board, image: image, completion: { (success) -> Void in
                    //
                    XCTAssertTrue(success, "Test image not uploaded")
                })
            }else{
                XCTFail("Test image not found")
            }
            }
        }
        
    }
    
    override func setUp() {
        super.setUp()
        deleteRealmFilesAtPath(realmPathForTesting)
        Realm.defaultPath = realmPathForTesting
    }
    
    override func tearDown() {
        super.tearDown()
        deleteRealmFilesAtPath(realmPathForTesting)
    }
}
