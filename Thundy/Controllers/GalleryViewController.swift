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
    
    @IBOutlet weak var safeAreaLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var superViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var safeAreaTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var superViewTrailingConstraint: NSLayoutConstraint!
    
    var customPhotoManager: CustomPhotoAlbum = (UIApplication.shared.delegate as! AppDelegate).customPhotosManager
    
    var allPhotos : PHFetchResult<PHAsset>? = nil
    
    let numberOfColumnsPortrait = 3
    let numberOfColumnsLandscape = 5
    
    var numOfColumns = 3
    var selectionModeEnabled = false
    var slideShowModeEnabled = false
    var navBarsHidden = false
    
    var commingFromHome = true
  
    let defaultViewTitle = "Your awesome photos!"
    let selectedPhotosViewTitle = "%d Photos selected"
    let selectedPhotoViewTitle = "%d Photo selected"
    let photoToDelete = "%d photo"
    let photosToDelete = "%d photos"
    
    let imageSelectionModeEnabled = UIImage(named: "cerrarSeleccion")
    let imageSelectionModeDisabled = UIImage(named: "seleccionar")

    var selectButton: UIBarButtonItem!
    
    var deleteButton: UIBarButtonItem = UIBarButtonItem()
    var shareButton: UIBarButtonItem = UIBarButtonItem()
    
    let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    var toolbarDefault = [UIBarButtonItem]()
    
    var shouldCloseViewController = false

    var prevIndexPathAtCenter: IndexPath?
    
    var currentIndexPath: IndexPath? {
        let indices = collectionView.indexPathsForVisibleItems.sorted{$0.row < $1.row}
        let firstIndex = indices.first
        return firstIndex
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if selectButton == nil {
            selectButton = UIBarButtonItem(image: imageSelectionModeDisabled, style: .plain, target: self, action: #selector(clickOnSelectionButton))
        }
    
        deleteButton = UIBarButtonItem(image: UIImage(named: "borrar"), style: .plain, target: self, action: #selector(deleteImages))
        shareButton = UIBarButtonItem(image: UIImage(named: "compartir"), style: .plain, target: self, action: #selector(shareImages))
        deleteButton.isEnabled = false
        shareButton.isEnabled = false
        toolbarDefault = [spacer, shareButton, spacer, deleteButton, spacer]
        
        navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        navigationController?.toolbar.isTranslucent = false
        navigationController?.toolbar.barTintColor = UIColor.defaultBlue
        navigationController?.toolbar.tintColor = UIColor.defaultWhite
        
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPressGR:)))
        longPressGR.minimumPressDuration = 0.5
        longPressGR.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(longPressGR)

    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.adjustToRotation()
        
        if let indexAtCenter = self.currentIndexPath {
            prevIndexPathAtCenter = indexAtCenter
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adjustConstraints()
        adjustToRotation()
        loadImages()
        
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        
        navigationController?.navigationBar.backgroundColor = UIColor.defaultBlue
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.navigationItem.title = self.defaultViewTitle
                self.navigationController?.toolbar.isTranslucent = false
                self.navigationController?.toolbar.backgroundColor = UIColor.defaultBlue
            })
        }
        
        statusBarView.backgroundColor = UIColor.defaultBlue
        navigationController?.navigationBar.topItem?.title = ""
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TypeOfTransition.shared.currentTransition = .DefaultSlide
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
  
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
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
    
    func adjustToRotation(){
        if UIDevice.current.orientation.isLandscape{
            numOfColumns = numberOfColumnsLandscape
        } else {
            numOfColumns = numberOfColumnsPortrait
        }
    }
    
    func loadImages(){
        customPhotoManager.getPhotos(albumTitle: customPhotoManager.photoAlbumName) { [weak self] (success, numberOfElements, photos) in
            if success {
                if numberOfElements! > 0 {
                    //Hay elementos, mostrar
                    self?.allPhotos = photos
                    self?.showEmptyState(show: false)
                    
                } else {
                    //No hay elementos, mostrar empty view
                    self?.allPhotos = photos
                    self?.showEmptyState(show: true)
                    
                }
            } else {
                //Mostrar Error
                print("Error cargando photos")
                DispatchQueue.main.async {
                    let alerta = UIAlertController(title: "Error", message: "Unspected error while loading photos, please try again", preferredStyle: .alert)
                    alerta.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                        self?.navigationController?.popViewController(animated: true)
                    }))
                    
                    self?.present(alerta, animated: true, completion: nil)
                }
            }
        }
      
    }
    
    func showEmptyState(show: Bool){
        DispatchQueue.main.async {
            
            if show {
                self.emptyStateView.isHidden = false
                self.navigationItem.rightBarButtonItem = nil
                self.navigationController?.setNavigationBarHidden(false, animated: true)
            } else {
                if !self.emptyStateView.isHidden {
                    self.emptyStateView.isHidden = true
                }
                if self.selectButton == nil {
                   self.selectButton = UIBarButtonItem(image: self.imageSelectionModeDisabled, style: .plain, target: self, action: #selector(self.clickOnSelectionButton))
                }
                self.navigationItem.setRightBarButton(self.selectButton, animated: true)
                self.collectionView.collectionViewLayout.invalidateLayout()
                self.collectionView.allowsMultipleSelection = true
            }
            
            self.collectionView.reloadData()
        }
    }
    
    @objc func deleteImages(){
        if let seleccion = self.collectionView.indexPathsForSelectedItems {
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
                    self.customPhotoManager.deletePhotos(assetsToDelete: assetsSelected!, completionHandler: { [weak self] (success, error, remainPhotos) in
                        if success{
                            self?.successDeletingPhotos(selectionToDelete: seleccion, remainPhotos: remainPhotos)
                        } else {
                            self?.errorDeletingPhotos()
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
            }) { [weak self] (finished) in
                if let itemsToReload = self?.collectionView.indexPathsForVisibleItems {
                    self?.collectionView.reloadItems(at: itemsToReload)
                    if self?.allPhotos == nil || self?.allPhotos?.count == 0 {
                        self?.setSelectionMode(on: false)
                        self?.showEmptyState(show: true)
                    } else {
                        self?.showSelectionTitle()
                    }
                }
            }
        }
        
    }
    
    @objc func shareImages(){
       
        var imagenesACompartirURL: [Any] = []
        imagenesACompartirURL.append(ShareTextProvider())
        
        if let listaDeImagenesSeleccionadas = self.collectionView.indexPathsForSelectedItems {
            for indexPath in listaDeImagenesSeleccionadas{
                let asset = self.allPhotos?.object(at: indexPath.row)
                let imagenUrl = UIImage().shareImage(asset: asset!)
                if let url = imagenUrl{
                    imagenesACompartirURL.append(url)
                }
            }
        }
        
        let activityViewController = UIActivityViewController(activityItems: imagenesACompartirURL, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
            
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
    
        cell.setImage(asset: asset!)
        
        if asset?.localIdentifier == TypeOfTransition.shared.currentAsset?.localIdentifier {
            cell.isHidden = true
        } else {
            cell.isHidden = false
        }
        
  
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let cellSize = calculateSizes(element: .Cell)
        return CGSize(width: cellSize, height: cellSize)
        
        }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        let footerHeight = calculateSizes(element: .TopMargin)
        return CGSize(width: view.frame.width, height: footerHeight)

    
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
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if selectionModeEnabled {
            return true
        }
        
        let attributes: UICollectionViewLayoutAttributes? = collectionView.layoutAttributesForItem(at: indexPath)
        let cellRect: CGRect? = attributes?.frame
        let cellFrameInSuperview = collectionView.convert(cellRect ?? CGRect.zero, to: collectionView.superview)
        let asset = allPhotos?.object(at: indexPath.row)
    
        TypeOfTransition.shared.setCellForAnimation(cellFrame: cellFrameInSuperview, indexPath: indexPath, cellAsset: asset!)
        TypeOfTransition.shared.currentTransition = .ImageSlide
        performSegue(withIdentifier: "imageToGalleryDetail", sender: indexPath)
       
        return false
     }
  
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showSelectionTitle()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        showSelectionTitle()
    }
    
    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let pathForFocusItem = prevIndexPathAtCenter, let layoutAttrs = collectionView.layoutAttributesForItem(at: pathForFocusItem) {
            return CGPoint(x: 0, y: layoutAttrs.frame.origin.y)

        } else {
            return proposedContentOffset
        }
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
        
        if longPressGR.state == .ended {
            return
        }
        
        if selectionModeEnabled {
            return
        }
        
        let point = longPressGR.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: point)
        
        if let indexPath = indexPath {
            setSelectionMode(on: true, selectIndexPath: indexPath)
        }
    }
    
    @objc func clickOnSelectionButton(){
        setSelectionMode(on: !selectionModeEnabled)
    }
    
    func setSelectionMode(on: Bool, selectIndexPath: IndexPath? = nil) {
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
            return screenWidth  * (0.05 / (CGFloat(numOfColumns) - 1))
        }
    }
    
    enum CollectionViewSizes {
        case Cell
        case TopMargin
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

       if segue.identifier == "imageToGalleryDetail" {
            if let element = sender as? IndexPath {
                commingFromHome = false
                let controlerDestino = segue.destination as! GalleryDetailViewController
                controlerDestino.allPhotos = allPhotos
                controlerDestino.delegate = self
                controlerDestino.startIndexPath = element
                navigationController?.toolbar.layoutIfNeeded()
                navigationController?.setToolbarHidden(false, animated: true)
            }
        }
    }

}
extension GalleryViewController: SendAllDeleted {
    func allDeleted(deleted: Bool) {
        if deleted{
            showEmptyState(show: true)
        }
    }
    
}


