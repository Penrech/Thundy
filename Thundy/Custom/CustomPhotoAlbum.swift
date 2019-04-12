//
//  CustomPhotoAlbum.swift
//  Thundy
//
//  Created by Pau Enrech on 09/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit
import Photos

//Esta clase incluye todas las variables y métodos necesarios para guardar imagenes en un album custom dentro de la galería

class CustomPhotoAlbum {
    
    let photoAlbumName = "Thundy"
    var albumReference: PHAssetCollection!
    
    //Esta función obtiene el album con el nombre correspondiente, si este album no existe, llama a la función crear album para crearlo
    func getAlbum(title: String, completionHandler: @escaping (PHAssetCollection?) -> ()) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", title)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            if let album = collections.firstObject {
                completionHandler(album)
                self!.albumReference = album
            } else {
                self?.createAlbum(withTitle: title, completionHandler: { (album) in
                    completionHandler(album)
                    self!.albumReference = album
                })
            }
        }
    }
    
    //Esta función se encarga de crear el album
    func createAlbum(withTitle title: String, completionHandler: @escaping (PHAssetCollection?) -> ()) {
        DispatchQueue.global(qos: .background).async {
            var placeholder: PHObjectPlaceholder?
            
            PHPhotoLibrary.shared().performChanges({
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                placeholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { (created, error) in
                var album: PHAssetCollection?
                if created {
                    let collectionFetchResult = placeholder.map { PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [$0.localIdentifier], options: nil) }
                    album = collectionFetchResult?.firstObject
                }
                
                completionHandler(album)
            })
        }
    }
    
    //Esta función guarda una foto en el album
    func save(photo: UIImage, toAlbum titled: String, completionHandler: @escaping (Bool, Error?) -> ()) {
        getAlbum(title: titled) { (album) in
            DispatchQueue.global(qos: .background).async {
                PHPhotoLibrary.shared().performChanges({
                    let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: photo)
                    let assets = assetRequest.placeholderForCreatedAsset
                        .map { [$0] as NSArray } ?? NSArray()
                    let albumChangeRequest = album.flatMap { PHAssetCollectionChangeRequest(for: $0) }
                    albumChangeRequest?.addAssets(assets)
                }, completionHandler: { (success, error) in
                    completionHandler(success, error)
                })
            }
        }
    }
    
    //Esta función obtiene todas las fotos del album
    func getPhotos(albumTitle: String, completionHandler: @escaping (_ success: Bool, _ quantity: Int?, _ photos: PHFetchResult<PHAsset>?) -> ()){
        let fetchOptions = PHFetchOptions()
        var allPhotos : PHFetchResult<PHAsset>? = nil
        
        getAlbum(title: albumTitle) { (album) in
            DispatchQueue.global(qos: .background).async {
                if let album = album {
                    allPhotos = PHAsset.fetchAssets(in: album, options: fetchOptions)
                    if allPhotos != nil {
                        completionHandler(true, allPhotos!.count, allPhotos)
                    } else {
                        completionHandler(false, nil, nil)
                    }
                } else {
                    completionHandler(false, nil, nil)
                }
            }
        }
    }
    
    //Esta función borra una o más fotos y devuelve las restantes.
    func deletePhotos(assetsToDelete: [PHAsset], completionHandler: @escaping (_ success: Bool, _ error: Error?, _ remainPhotos: PHFetchResult<PHAsset>?) -> ()){
        var remainPhotos: PHFetchResult<PHAsset>?
        PHPhotoLibrary.shared().performChanges({
            if let album = self.albumReference, let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) {
                albumChangeRequest.removeAssets(assetsToDelete as NSFastEnumeration)
            }
        }, completionHandler: { (success, error) in
            if let album = self.albumReference{
                remainPhotos = PHAsset.fetchAssets(in: album, options: PHFetchOptions())
            }
            completionHandler(success, error, remainPhotos)
        })
    }
    
    
}
