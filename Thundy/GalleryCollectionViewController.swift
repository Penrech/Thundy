//
//  GalleryCollectionViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 01/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "Cell"

class GalleryCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var buttonDelete: UIBarButtonItem!
    var allPhotos : PHFetchResult<PHAsset>? = nil {
        didSet{
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.collectionViewLayout.invalidateLayout()
            }
        }
    }
    
    
    let numOfColumns = 3
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let fetchOptions = PHFetchOptions()
        self.allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        self.collectionView.allowsMultipleSelection = true

        buttonDelete.customView?.isHidden = true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        navigationController?.navigationBar.backgroundColor = UIColor.init(red: 102/255, green: 230/255, blue: 1, alpha: 1)
        DispatchQueue.main.async {
            self.navigationItem.title = "Your awesome photos!"
        }
        navigationController?.navigationBar.topItem?.title = ""
        
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        statusBarView.backgroundColor = UIColor.init(red: 102/255, green: 230/255, blue: 1, alpha: 1)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if let allPhotos = allPhotos {
            return allPhotos.count
        } else {
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        let asset = allPhotos?.object(at: indexPath.row)
        // Configure the cell
        cell.libraryImage.fetchImage(asset: asset!, contentMode: .aspectFill, targetSize: cell.libraryImage.frame.size)
    
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = calculateSizes(element: .Cell)
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let headerHeight = calculateSizes(element: .TopMargin)
        return CGSize(width: view.frame.width, height: headerHeight)
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return calculateSizes(element: .TopMargin)
    }
    
    func calculateSizes(element: CollectionViewSizes) -> CGFloat{
        let screenWidth = view.frame.width
        
        switch element {
        case .Cell:
            return (screenWidth / CGFloat(numOfColumns)) * 0.95
        case .TopMargin:
            return screenWidth  * 0.025
        }
    }
    
    enum CollectionViewSizes {
        case Cell
        case TopMargin
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */
    

    
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        print("longClick on \(indexPath.row)")
        self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .right)
        print("Seleccion actual \(self.collectionView.indexPathsForSelectedItems)")
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    
    /*override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
    }*/
    

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        print("Uso esto \(sender)")
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return false
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendImageToDetail"{
            let selectedImage = self.collectionView.indexPathsForSelectedItems
            let asset = allPhotos?.object(at: selectedImage![0].row)
            let controlerDestino = segue.destination as! DetailImageViewController
            controlerDestino.asset = asset!
        }
    }
    
}
