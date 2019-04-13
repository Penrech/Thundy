//
//  GalleryViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 03/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "Cell"

class GalleryViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var buttonDelete: UIBarButtonItem!
    @IBOutlet weak var emptyStateView: UIView!
    
    var customPhotoManager: CustomPhotoAlbum = (UIApplication.shared.delegate as! AppDelegate).customPhotosManager
    
    var allPhotos : PHFetchResult<PHAsset>? = nil
    
    let numOfColumns = 3
    var selectionModeEnabled = false
    var slideShowModeEnabled = false
    var navBarsHidden = false
  
    let defaultViewTitle = "Your awesome photos!"
    let selectedPhotosViewTitle = "%d Photos selected"
    let selectedPhotoViewTitle = "%d Photo selected"
    let photoToDelete = "%d photo"
    let photosToDelete = "%d photos"
    
    let imageSelectionModeEnabled = UIImage(named: "endSelection")!.escalarImagen(nuevaAnchura: 34)
    let imageSelectionModeDisabled = UIImage(named: "startSelection")!.escalarImagen(nuevaAnchura: 34)

    var selectButton: UIBarButtonItem!
    var closeSlideShowMode: UIBarButtonItem = UIBarButtonItem()
    
    var deleteButton: UIBarButtonItem = UIBarButtonItem()
    var shareButton: UIBarButtonItem = UIBarButtonItem()
    
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    var toolbarDefault = [UIBarButtonItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if selectButton == nil {
            selectButton = UIBarButtonItem(image: imageSelectionModeDisabled, style: .plain, target: self, action: #selector(clickOnSelectionButton))
        }
        closeSlideShowMode = UIBarButtonItem(image: UIImage(named: "close")?.escalarImagen(nuevaAnchura: 36), style: .plain, target: self, action: #selector(disableSlideShowMode))
    
        deleteButton = UIBarButtonItem(image: UIImage(named: "delete")?.escalarImagen(nuevaAnchura: 36), style: .plain, target: self, action: #selector(deleteImages))
        shareButton = UIBarButtonItem(image: UIImage(named: "share")?.escalarImagen(nuevaAnchura: 36), style: .plain, target: self, action: #selector(shareImages))
        deleteButton.isEnabled = false
        shareButton.isEnabled = false
        toolbarDefault = [spacer, shareButton, spacer, deleteButton, spacer]
        
        navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        navigationController?.toolbar.isTranslucent = false
        navigationController?.toolbar.barTintColor = UIColor.defaultBlue
        navigationController?.toolbar.tintColor = UIColor.defaultWhite
        print(" Valor de translates : \(navigationController?.toolbar.translatesAutoresizingMaskIntoConstraints)" )
        
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPressGR:)))
        longPressGR.minimumPressDuration = 0.5
        longPressGR.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(longPressGR)

    }
  
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool{
        return navBarsHidden
    }
    
    func loadImages(){
        customPhotoManager.getPhotos(albumTitle: customPhotoManager.photoAlbumName) { (success, numberOfElements, photos) in
            if success {
                if numberOfElements! > 0 {
                    //Hay elementos, mostrar
                    self.allPhotos = photos
                    self.showEmptyState(show: false)
                    
                } else {
                    //No hay elementos, mostrar empty view
                    print("Album vacio")
                    self.showEmptyState(show: true)
                    
                }
            } else {
                //Mostrar Error
                print("Error cargando photos")
            }
        }
      
    }
    
    func showEmptyState(show: Bool){
        DispatchQueue.main.async {
            if show {
                self.emptyStateView.isHidden = false
                self.navigationItem.rightBarButtonItem = nil
            } else {
                if !self.emptyStateView.isHidden {
                    self.emptyStateView.isHidden = true
                }
                
                if self.selectButton == nil {
                   self.selectButton = UIBarButtonItem(image: self.imageSelectionModeDisabled, style: .plain, target: self, action: #selector(self.clickOnSelectionButton))
                }
                self.navigationItem.setRightBarButton(self.selectButton, animated: true)
                self.collectionView.reloadData()
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.allowsMultipleSelection = true
            }
        }
    }
    
    @objc func deleteImages(){
        if let seleccion = self.collectionView.indexPathsForSelectedItems{
            var indexPaths: [Int] = []
            for index in seleccion {
                indexPaths.append(index.row)
            }
            let indexSet = IndexSet(indexPaths)
            
            let assetsSelected = allPhotos?.objects(at: indexSet)
            
            let elements = seleccion.count > 1 ? String(format: photosToDelete, seleccion.count) : String(format: photoToDelete, seleccion.count)
            let alert = UIAlertController(title: "Delete", message: "Are you sure that you want to delete \(elements), this action can't be undone", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                if assetsSelected != nil {
                    self.customPhotoManager.deletePhotos(assetsToDelete: assetsSelected!, completionHandler: { (success, error, remainPhotos) in
                        if success{
                            self.successDeletingPhotos(selectionToDelete: seleccion, remainPhotos: remainPhotos)
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
                self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
                if self.allPhotos == nil || self.allPhotos?.count == 0 {
                    self.setSelectionMode(on: false)
                    self.showEmptyState(show: true)
                } else {
                    self.showSelectionTitle()
                }
                
            }
        }
        
    }
    
    @objc func shareImages(){
       
        var imagenesACompartir: [UIImage] = []
        if let listaDeImagenesSeleccionadas = self.collectionView.indexPathsForSelectedItems {
            for indexPath in listaDeImagenesSeleccionadas{
                let asset = self.allPhotos?.object(at: indexPath.row)
                let image = UIImage().getAssetImage(asset: asset!)
                imagenesACompartir.append(image)
                
            }
        }
        
        let activityViewController = UIActivityViewController(activityItems: imagenesACompartir, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
            
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadImages()
   
        /*let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")*/
        navigationController?.navigationBar.backgroundColor = UIColor.defaultBlue
        DispatchQueue.main.async {
            self.navigationItem.title = "Your awesome photos!"
        }
        navigationController?.navigationBar.topItem?.title = ""
        navigationController?.hidesBarsOnSwipe = true
        navigationController?.toolbar.autoresizesSubviews = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        statusBarView.backgroundColor = UIColor.defaultBlue
        
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
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let allPhotos = allPhotos{
            return allPhotos.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        let asset = allPhotos?.object(at: indexPath.row)
    
        if !slideShowModeEnabled {
            cell.setImage(asset: asset!)
            //cell.libraryImage.fetchImage(asset: asset!, contentMode: .aspectFill, targetSize: cell.libraryImage.frame.size)
        } else {
            cell.setImageDetail(asset: asset!)
            //cell.libraryImage.fetchImage(asset: asset!, contentMode: .aspectFit)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        if !slideShowModeEnabled{
            let cellSize = calculateSizes(element: .Cell)
            return CGSize(width: cellSize, height: cellSize)
        }
        let screenSize = UIScreen.main.bounds
        return CGSize(width: screenSize.width , height: screenSize.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        if !slideShowModeEnabled{
            let footerHeight = calculateSizes(element: .TopMargin)
            return CGSize(width: view.frame.width, height: footerHeight)
        }
        return CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if !slideShowModeEnabled {
            let headerHeight = calculateSizes(element: .TopMargin)
            return CGSize(width: view.frame.width, height: headerHeight)
            
        }
        return CGSize(width: 0, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if !slideShowModeEnabled {
            return 1.0
        }
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if !slideShowModeEnabled {
            return calculateSizes(element: .TopMargin)
        }
        return 0.0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if selectionModeEnabled {
            return true
        }
        
        //performSegue(withIdentifier: "showImageInDetail", sender: indexPath.row)*/
        if !slideShowModeEnabled{
            print("ContentOffset antes: \(collectionView.contentOffset)")
            slideShowImage(moveToClicked: indexPath)
            print("ContentOffset despuse: \(collectionView.contentOffset)")
        } else {
            if !navigationController!.navigationBar.isHidden && !navigationController!.toolbar.isHidden{
                navigationController?.setToolbarHidden(true, animated: true)
                navigationController?.setNavigationBarHidden(true, animated: true)
                navBarsHidden = true
                UIView.animate(withDuration: 0.15) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
                
                
            } else {
                navigationController?.setToolbarHidden(false, animated: true)
                navigationController?.setNavigationBarHidden(false, animated: true)
                navBarsHidden = false
                UIView.animate(withDuration: 0.15) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
                
            }
            
        }
        
        return false
     }
  
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showSelectionTitle()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        showSelectionTitle()
    }
    
    
    func showSelectionTitle(){
        if let numberOfSelections = collectionView.indexPathsForSelectedItems?.count {
            if numberOfSelections == 0 {
                shareButton.isEnabled = false
                deleteButton.isEnabled = false
            }
            if numberOfSelections == 1 {
                navigationItem.title = String(format: selectedPhotoViewTitle, numberOfSelections)
                shareButton.isEnabled = true
                deleteButton.isEnabled = true
                return
            }
            navigationItem.title = String(format: selectedPhotosViewTitle, numberOfSelections)
        }
    }
    
    @objc func handleLongPress(longPressGR: UILongPressGestureRecognizer) {
        if slideShowModeEnabled {
            return
        }
        
        if longPressGR.state == .ended {
            return
        }
        
        if selectionModeEnabled {
            return
        }
        
        let point = longPressGR.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)
        
        if let indexPath = indexPath {
            var cell = self.collectionView.cellForItem(at: indexPath)
            setSelectionMode(on: true, selectIndexPath: indexPath)
        }
    }
    
    @objc func clickOnSelectionButton(){
        setSelectionMode(on: !selectionModeEnabled)
    }
    
    func setSelectionMode(on: Bool, selectIndexPath: IndexPath? = nil){
        selectionModeEnabled = !selectionModeEnabled
        
        if on {
            if let indexPath = selectIndexPath {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
            
            navigationItem.rightBarButtonItem!.image = imageSelectionModeEnabled
            showSelectionTitle()
            navigationItem.hidesBackButton = true
            if (navigationController?.navigationBar.isHidden)! {
                navigationController?.setNavigationBarHidden(false, animated: true)
            }
            
            navigationController?.hidesBarsOnSwipe = false
            toolbarItems = toolbarDefault
            navigationController?.setToolbarHidden(false, animated: true)
            
            
        } else {
            navigationItem.rightBarButtonItem!.image = imageSelectionModeDisabled
            navigationItem.title = defaultViewTitle
            navigationItem.hidesBackButton = false
            navigationController?.hidesBarsOnSwipe = true
            navigationController?.setToolbarHidden(true, animated: true)
            toolbarItems = nil
            //Deselect all
            if let totalSelection = collectionView.indexPathsForSelectedItems {
                for selection in totalSelection {
                    collectionView.deselectItem(at: selection, animated: false)
                }
            }
        }
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
    
    @objc func disableSlideShowMode(){
        backToNormalGallery()
    }

    func slideShowImage(moveToClicked: IndexPath){

        self.collectionView.backgroundColor = .black
        
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.slideShowModeEnabled = true
        self.collectionView.reloadData()
        
        self.collectionView.isPagingEnabled = true
        self.navigationItem.hidesBackButton = true
        
        
        if self.navigationController!.navigationBar.isHidden {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        self.shareButton.isEnabled = true
        self.deleteButton.isEnabled = true
        self.toolbarItems = self.toolbarDefault
        self.navigationController?.setToolbarHidden(false, animated: true)

        self.navigationController?.hidesBarsOnSwipe = false
        self.navigationItem.rightBarButtonItem = self.closeSlideShowMode
        
        if let layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal  // .horizontal
        }
        
        self.collectionView.scrollToItem(at: moveToClicked, at: .centeredHorizontally, animated: false)
        
    }
    
    func backToNormalGallery(){
        collectionView.contentInsetAdjustmentBehavior = .always
        slideShowModeEnabled = false
        collectionView.reloadData()
        
        collectionView.isPagingEnabled = false
        collectionView.backgroundColor = .clear
        navigationItem.hidesBackButton = false
        
        shareButton.isEnabled = false
        deleteButton.isEnabled = false
        toolbarItems = nil
        if !navigationController!.toolbar.isHidden {
            navigationController?.setToolbarHidden(true, animated: true)
        }
        
        if !UIApplication.shared.isStatusBarHidden {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        navigationController?.hidesBarsOnSwipe = true
        navigationItem.rightBarButtonItem = selectButton
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical  // .horizontal
        }
        
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "ImageToDetail"{
            if let elementPosition = sender as? Int {
                let asset = allPhotos?.object(at: elementPosition)
                let controlerDestino = segue.destination as! DetailImageViewController
                controlerDestino.asset = asset!
            }
        }
    }

}
