//
//  StylesVC.swift
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
import MobileCoreServices

class StylesVC: UICollectionViewController, CollectionViewWaterfallLayoutDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let reuseIdentifier = "Cell"
    
    var board: Board!
    
    var networkRequest: Alamofire.Request?
    
    var styles = [Style]()
    
    var populatingPhotos = false
    var currentPage = 1
    
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
        println(board)

        let boardStyles = Realm().objects(Style).filter("board == %@", board)
        for style in boardStyles{
            styles.append(style)
            println(style)
        }

        collectionView?.reloadData()
        populatePhotos()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        networkRequest?.cancel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UICollectionViewDelegate
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        println("styles.count: \(styles.count)")
        return styles.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ThumbnailCell
        
        let style = styleAtIndexPath(indexPath)
        
        cell.imageView.image = style.thumbnail
        
        cell.request?.cancel()
        
        if style.thumbnail == nil  {
            // Download from the internet
            if let url = style.thumbnailUrl{
                cell.downloadImage(url, completion: { (image) -> Void in
                    let realm = Realm()
                    realm.write {
                        style.thumbnail = image
                    }
                })
            }
            
        }
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.item == (styles.count - 1) {
            println("load more content")
            populatePhotos()
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        //If the cell went off-screen before the image was downloaded, cancel request.
        let theCell = cell as! ThumbnailCell
        theCell.request?.cancel()
    }
    
    // MARK: WaterfallLayoutDelegate
    func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let style = styleAtIndexPath(indexPath)
        return style.size
    }
    
    //MARK: - Uploading photo
    @IBAction func uploadStyle(sender: UIBarButtonItem) {
        pickPhoto()
    }
    
    func pickPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as! String]
        imagePicker.sourceType = .SavedPhotosAlbum
        imagePicker.allowsEditing = false
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true) {}
    }
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
            
            if let im = info[UIImagePickerControllerOriginalImage] as? UIImage{
                StyleItManagerSingleton.uploadStyleForBoard(board, image: im, completion: { [unowned self] (success) -> Void in
                    //Reload
                     self.populatePhotos()
                })
            }
            
            
            dismissViewControllerAnimated(true) {}
    }
    //MARK: - Utilities
    func populatePhotos(){
        if populatingPhotos { // Do not populate more photos if we're in the process of loading a page
            return
        }
        
        populatingPhotos = true
        
        networkRequest = StyleItManagerSingleton.updateStylesForBoard(board, page: currentPage) { [unowned self] (styles, error) -> Void in
            println("populatePhotos")
            if let error = error {
                println("Error: \(error)")
            } else {
                // Processing the photos and updating the model takes a while, do not dispatch on the main queue.
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {

                    
                    if let styles = styles{
                        println(styles.count)
                        
                        let stylesCount = self.styles.count
                        self.styles.extend(styles)

                        // Needed for insertItemsAtIndexPaths
                        let indexPaths = (stylesCount..<self.styles.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            // Better than self.collectionview!.reloadData() as it only adds new items instead of reloading the entire collection view
                            if self.currentPage == 1{
                                self.collectionView?.reloadData()
                            }else{
                                self.collectionView?.insertItemsAtIndexPaths(indexPaths)
                            }
                            
                        }
                        
                        self.currentPage++
                    }
                    
                    self.populatingPhotos = false
//                }
                
                
            }
        }
        
        
    }
    
    @IBAction func reloadData(sender: UIBarButtonItem) {
        populatePhotos()
    }
    
    func styleAtIndexPath(indexPath: NSIndexPath) -> Style{
        let style = styles[indexPath.row]
        return style
    }
    
    //MARK: - UIScrollViewDelegate
//    override func scrollViewDidScroll(scrollView: UIScrollView) {
//        //
//        if navigationController?.visibleViewController != self{
//            return
//        }
//        // Populate more photos when the scrollbar indicator is at 80%
//        if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8 {
//            populatePhotos()
//        }
//    }
}
