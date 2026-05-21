//
//  PanoramaFetcher.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import Foundation
import Combine
import Photos

class PanoramaFetcher: ObservableObject {
    @Published var panoramas: [PHAsset] = []
    @Published var accessGranted: Bool = false
    
    func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.accessGranted = true
                    self?.fetchPanoramas()
                default:
                    self?.accessGranted = false
                }
            }
        }
    }
    
    private func fetchPanoramas() {
       let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoPanorama.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var fetchedAssets: [PHAsset] = []
        fetchResult.enumerateObjects { (asset, index, stop) in
            fetchedAssets.append(asset)
        }
        
        self.panoramas = fetchedAssets
    }

}
