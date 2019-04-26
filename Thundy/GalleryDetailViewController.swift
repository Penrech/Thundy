//
//  GalleryDetailViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 16/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import Photos

private let reuseIndentifier = "Cell"

protocol SendAllDeleted: class {
    func allDeleted(deleted: Bool)
}

class GalleryDetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
   
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var safeAreaLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var safeAreaTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var superViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var superViewTrailingConstraint: NSLayoutConstraint!
    
    fileprivate var prevIndexPathAtCenter: IndexPath?
    
    fileprivate var currentIndexPath: IndexPath? {
        let center = view.convert(collectionView.center, to: collectionView)
        return collectionView.indexPathForItem(at: center)
    }
    
    var delegate: SendAllDeleted?
    
    var allPhotos : PHFetchResult<PHAsset>? = nil
    var startIndexPath = IndexPath(row: 0, section: 0)
    var customPhotoManager: CustomPhotoAlbum = (UIApplication.shared.delegate as! AppDelegate).customPhotosManager
    
    var navBarsVisible = true
    var hideStatusBar = false
    
    var actualPage = 0
    
    var viewRotating = false
    
    var deleteButton: UIBarButtonItem = UIBarButtonItem()
    var shareButton: UIBarButtonItem = UIBarButtonItem()
    var backButton: UIBarButtonItem = UIBarButtonItem()
    
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    var noMorePhotos = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsSelection = true
        collectionView.isPagingEnabled = true
        self.collectionView.contentInsetAdjustmentBehavior = .never
        print("Layout: \(self.collectionView.frame)")
        
        self.extendedLayoutIncludesOpaqueBars = true
        
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView))
        doubleTapRecognizer.numberOfTapsRequired = 2
        collectionView.addGestureRecognizer(doubleTapRecognizer)
  
        actualPage = startIndexPath.row
        collectionView.layoutIfNeeded()
        self.collectionView.scrollToItem(at: startIndexPath, at: .centeredHorizontally, animated: true)
        
        backButton = UIBarButtonItem(image: UIImage(named: "close")?.escalarImagen(nuevaAnchura: 32), style: .plain, target: self, action: #selector(backToPreviousViewController))
        deleteButton = UIBarButtonItem(image: UIImage(named: "delete")?.escalarImagen(nuevaAnchura: 28), style: .plain, target: self, action: #selector(deleteImage))
        shareButton = UIBarButtonItem(image: UIImage(named: "share")?.escalarImagen(nuevaAnchura: 28), style: .plain, target: self, action: #selector(shareImage))
        
        navigationItem.leftBarButtonItem = backButton
    
        
    }
    
    func adjustConstraints(){
        if UIDevice.current.hasNotch{
            safeAreaLeadingConstraint.priority = .defaultLow
            safeAreaTrailingConstraint.priority = .defaultLow
            superViewLeadingConstraint.priority = .defaultHigh
            superViewTrailingConstraint.priority = .defaultHigh
        } else {
            safeAreaLeadingConstraint.priority = .defaultHigh
            safeAreaTrailingConstraint.priority = .defaultHigh
            superViewLeadingConstraint.priority = .defaultLow
            superViewTrailingConstraint.priority = .defaultLow
        }
    }
   @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        let actualIndexPath = collectionView.indexPathsForVisibleItems[0]
        let actualCell = collectionView.cellForItem(at: actualIndexPath) as! PhotoDetailViewCell
        
        //Check if is bounds
        let boundsOfView = actualCell.detailImageView.bounds
        let placeTouched = recognizer.location(in: actualCell.detailImageView)
        if placeTouched.x >= 0.0 && placeTouched.x <= boundsOfView.width && placeTouched.y >= 0.0 && placeTouched.y <= boundsOfView.height{
            print("Envio pulsación")
            actualCell.recieveDataFromDoubleTap(recognizer: recognizer)
        }
        print("Localizacion: \(recognizer.location(in: actualCell.detailImageView))")
    }
    
    @objc func backToPreviousViewController() {
        closeViewController()
    }
    
    func closeViewController(){
        navigationController?.setToolbarHidden(true, animated: true)
        
        if noMorePhotos {
            self.delegate?.allDeleted(deleted: true)
        }

        let currentCellIndexPath = collectionView.indexPathsForVisibleItems[0]
        let currentCell = collectionView.cellForItem(at: currentCellIndexPath)! as! PhotoDetailViewCell
        let currentImageViewFrame = currentCell.detailImageView.frame
        let asset = allPhotos?.object(at: currentCellIndexPath.row)
        
        TypeOfTransition.shared.currentTransition = .ImageSlide
        TypeOfTransition.shared.setCellForAnimation(cellFrame: currentImageViewFrame, indexPath: currentCellIndexPath, cellAsset: asset!)
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adjustConstraints()
        
        if UIDevice.current.orientation.isLandscape{
            hideStatusBar = true
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        self.toolbarItems = [spacer, shareButton, spacer, deleteButton, spacer]
        self.navigationController?.navigationBar.topItem?.title = ""
        
        navigationController?.hidesBarsOnSwipe = false
        print("BoundsOfCollection: \(self.collectionView.bounds)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("Celdas Visibles: \(collectionView.indexPathsForVisibleItems.count)")
        super.viewDidAppear(animated)
        
        if navigationController!.isNavigationBarHidden {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        navigationController?.setToolbarHidden(false, animated: true)
        
        UIView.animate(withDuration: 0.3) {
            
            self.navigationController?.navigationBar.backgroundColor = UIColor.defaultBlueTranslucent
            guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
                return
            }
            statusBarView.backgroundColor = UIColor.defaultBlueTranslucent
            
            self.navigationController?.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
            self.navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
            self.navigationController?.toolbar.isTranslucent = true
            print(self.navigationController?.toolbar.backgroundImage(forToolbarPosition: UIBarPosition.any, barMetrics: .default))
            /*if let image = self.navigationController?.toolbar.backgroundImage(forToolbarPosition: .any, barMetrics: .default){
                print("Entro aqui")
                let newImage = image.alpha(0.65)
                self.navigationController?.toolbar.setBackgroundImage(newImage, forToolbarPosition: .any, barMetrics: .default)
            }*/
            self.navigationController?.toolbar.backgroundColor = UIColor.defaultBlueTranslucent
            
        }
    }
    
    func moveOffset(toBounds: CGSize){
        let collectionBounds = collectionView.bounds
        let actualCellNumber = collectionBounds.minX / collectionBounds.width
        let offsetX = CGFloat(actualCellNumber) * toBounds.width
        collectionView.contentOffset = CGPoint(x: offsetX, y: 0)
    }
    
    func setAnchorProperly(indexPath: IndexPath, toBounds: CGSize){
        let collectionBounds = collectionView.bounds
        let actualCellNumber = indexPath.row
        let offsetX = CGFloat(actualCellNumber) * toBounds.width
       
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let currentIndexPath2 = collectionView.indexPathsForVisibleItems[0]
        let currentCell = collectionView.cellForItem(at: currentIndexPath2) as! PhotoDetailViewCell
    
    
        if let indexAtCenter = currentIndexPath {
            prevIndexPathAtCenter = indexAtCenter
        }
        collectionView.collectionViewLayout.invalidateLayout()
        
        coordinator.animate(alongsideTransition: { (transitionContext) in
            
            currentCell.setImageWhenRotate()
            //self.setAnchorProperly(indexPath: currentIndexPath, toBounds: size)
            //self.collectionView.selectItem(at: currentIndexPath, animated: false, scrollPosition: .centeredHorizontally)
            if UIDevice.current.orientation.isLandscape {
                self.manageHideStatusOfBars(type: .hideStatusBar)
            } else {
                self.manageHideStatusOfBars(type: .showStatusBar)
            }

        }) { (completion) in
           
            //self.viewRotating = false
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let oldCenter = prevIndexPathAtCenter else {
            return proposedContentOffset
        }
        
        let attrs =  collectionView.layoutAttributesForItem(at: oldCenter)
        
        let newOriginForOldIndex = attrs?.frame.origin
        
        return newOriginForOldIndex ?? proposedContentOffset
    }
    
    func manageHideStatusOfBars(type: typeOfBarHide){
        switch type {
        case .showStatusBar:
            if !navBarsVisible {
                return
            }
            self.hideStatusBar = false
            self.setNeedsStatusBarAppearanceUpdate()
        case .hideStatusBar:
            self.hideStatusBar = true
            self.setNeedsStatusBarAppearanceUpdate()
        case .showAllbars:
            self.hideToolbars(show: true)
        case .hideAllBars:
            self.hideToolbars(show: false)
        }
    }
    
    enum typeOfBarHide {
        case hideStatusBar
        case showStatusBar
        case hideAllBars
        case showAllbars
    }
 

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool{
        return hideStatusBar
    }

    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    @objc func deleteImage(){
        
        let indexOfPhoto = collectionView.indexPathsForVisibleItems[0]
        let assetSelected = allPhotos?.object(at: indexOfPhoto.row)
    
        let alert = UIAlertController(title: "Delete", message: "Are you sure that you want to delete the actual photo?, this action can't be undone", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            if assetSelected != nil {
                self.customPhotoManager.deletePhotos(assetsToDelete: [assetSelected!], completionHandler: { (success, error, remainPhotos) in
                    if success{
                        self.successDeletingPhotos(selectionToDelete: [indexOfPhoto], remainPhotos: remainPhotos)
                    } else {
                        self.errorDeletingPhotos()
                    }
                })
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        present(alert, animated: true, completion: nil)

    }
    
    func errorDeletingPhotos(){
        let alert = UIAlertController(title: "Error", message: "Error removing the photos", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func successDeletingPhotos(selectionToDelete: [IndexPath], remainPhotos: PHFetchResult<PHAsset>?){
        OperationQueue.main.addOperation {
            
            self.allPhotos = remainPhotos
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: selectionToDelete)
            }) { (finished) in
                let visibleItems = self.collectionView.indexPathsForVisibleItems
                if visibleItems.count > 0 {
                    self.collectionView.reloadItems(at: visibleItems)
                }
                print(self.allPhotos)
                if self.allPhotos?.count == 0 {
                    //Mover al inicial, mostrar que no hay nada
                    self.noMorePhotos = true
                    self.closeViewController()
                } 
            }
        }
    }
    
    @objc func shareImage(){
        
        let indice = self.collectionView.indexPathsForVisibleItems[0]
        let asset = self.allPhotos?.object(at: indice.row)
        let imagenUrlACompartir = UIImage().shareImage(asset: asset!)
      
        let activityViewController = UIActivityViewController(activityItems: [imagenUrlACompartir], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    func hideToolbars(show: Bool){
        if !show && navBarsVisible{
            navigationController?.setToolbarHidden(true, animated: true)
            navigationController?.setNavigationBarHidden(true, animated: true)
            navBarsVisible = false
            hideStatusBar = true
            UIView.animate(withDuration: 0.15) {
                self.setNeedsStatusBarAppearanceUpdate()
                self.collectionView.backgroundColor = .black
            }
            
        } else if show && !navBarsVisible{
            navigationController?.setToolbarHidden(false, animated: true)
            navigationController?.setNavigationBarHidden(false, animated: true)
            navBarsVisible = true
            hideStatusBar = UIDevice.current.orientation.isLandscape 
            UIView.animate(withDuration: 0.15) {
                self.setNeedsStatusBarAppearanceUpdate()
                self.collectionView.backgroundColor = .clear
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let x = scrollView.contentOffset.x
        let w = scrollView.bounds.size.width
        let currentPage = Int(ceil(x/w))
         print("Current Page: \(currentPage)")
        
        
        let lastCell = collectionView.cellForItem(at: IndexPath(row: currentPage + 1, section: 0))
        print("@ScrollViewDidEndDecelerating")
        print("ContentOffset : \(collectionView.contentOffset)")
        /*if currentPage == actualPage{
            return
        }
        
        actualPage = currentPage
        
        let currentIndexPath = IndexPath(row: currentPage, section: 0)
        let asset = allPhotos?.object(at: currentIndexPath.row)
        UIView.animate(withDuration: 0.3) {
            if let asset = asset, let date = asset.creationDate {
                let dateFormater = DateFormatter()
                dateFormater.dateStyle = .medium
                self.navigationItem.title = dateFormater.string(from: date)
            }
        }*/
        
    }
    
    /*func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Seleccionado \(indexPath)")
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        print("seleccionado \(indexPath)")
        return true
    }
    
    */func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //let asset = allPhotos?.object(at: indexPath.row)
        print("@willdisplaying \(indexPath)")
    }
    
  
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        /*print("Deja de verse el indexPath \(indexPath)")
        print("Celda visible: \(collectionView.indexPathsForVisibleItems)")*/
        print("@didEndDisplaying \(indexPath)")
        if let indiceActual = collectionView.indexPathsForVisibleItems.first{
            let asset = allPhotos?.object(at: indiceActual.row)
            UIView.animate(withDuration: 0.3) {
                if let asset = asset, let date = asset.creationDate {
                    let dateFormater = DateFormatter()
                    dateFormater.dateStyle = .medium
                    self.navigationItem.title = dateFormater.string(from: date)
                }
            }
            
        }
        /*let cellDeleted = cell as! PhotoDetailViewCell
        cellDeleted.restoreZoom()*/
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let allPhotos = allPhotos{
            return allPhotos.count
            
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIndentifier, for: indexPath) as! PhotoDetailViewCell
        let asset = allPhotos?.object(at: indexPath.row)
        
        print("Nueva celda")
        
        cell.setImageDetail(asset: asset!)
        cell.delegate = self
        
        return cell
    }
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize = UIScreen.main.bounds
        return CGSize(width: screenSize.width , height: screenSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    

}
extension GalleryDetailViewController: cellZoomDelegate {
    func cellDidZoom(toDefaultZoom: Bool) {
        print("Celda hace zoom")
        if !toDefaultZoom {
            manageHideStatusOfBars(type: .hideAllBars)
        }
    }
    
}
