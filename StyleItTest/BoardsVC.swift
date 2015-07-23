//
//  BoardsVC.swift
//  StyleItTest
//
//  Created by Dmitry Shmidt on 7/17/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.
//

import UIKit
import RealmSwift
import UIKit
import CollectionViewWaterfallLayout
import Alamofire

class BoardsVC: UICollectionViewController, CollectionViewWaterfallLayoutDelegate  {
    
    private let reuseIdentifier = "Cell"
    var notificationToken: NotificationToken?
    var items = Realm().objects(Board)
    
    deinit{
        if let notificationToken = notificationToken{
            Realm().removeNotification(notificationToken)
        }
    }
    
    func setupView() {
        let layout = CollectionViewWaterfallLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        layout.minimumColumnSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        collectionView?.collectionViewLayout = layout
        collectionView?.alwaysBounceVertical = true
        
        let nibCell = UINib(nibName: "ThumbnailCell", bundle:nil)
        self.collectionView?.registerNib(nibCell, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        // Set realm notification block
        notificationToken = Realm().addNotificationBlock { [unowned self] note, realm in
            self.collectionView?.reloadData()
        }

        reloadThumbnails()        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let vc = storyboard?.instantiateViewControllerWithIdentifier("StylesVC") as! StylesVC
        vc.board = boardAtIndexPath(indexPath)
        showViewController(vc, sender: self)
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return items.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ThumbnailCell
        
        let board = boardAtIndexPath(indexPath)
        cell.imageView.image = board.thumbnail
        
        cell.request?.cancel()
        
        if board.thumbnail == nil  {
            println("No thumbnail, downloading it")
            // Download from the internet
            if let url = board.thumbnailUrl{
                cell.downloadImage(url, completion: { (image) -> Void in
                    let realm = Realm()
                    realm.write {
                        board.thumbnail = image
                    }
                })
            }

        }

        return cell
    }
    
    // MARK: WaterfallLayoutDelegate
    func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let board = boardAtIndexPath(indexPath)
        return board.size
    }
    
    //MARK: - Utilities
    func reloadThumbnails(){
        StyleItManagerSingleton.updateBoardsFromServer { [unowned self](results, error) -> Void in

            self.collectionView?.reloadData()
        }
    }
    
    @IBAction func reloadData(sender: UIBarButtonItem) {
        reloadThumbnails()
    }
    
    func boardAtIndexPath(indexPath: NSIndexPath) -> Board{
        let board = items[indexPath.row]
        return board
    }
}
