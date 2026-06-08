//
//  PanoramaFetcher.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import Foundation
import Combine
import Photos

class PanoramaFetcher: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    
    @Published var panoramas: [PHAsset] = []
    @Published var accessGranted: Bool = false
    private var fetchResult: PHFetchResult<PHAsset>?
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
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
        
        self.fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var fetchedAssets: [PHAsset] = []
        self.fetchResult?.enumerateObjects { (asset, index, stop) in
            fetchedAssets.append(asset)
        }
        
        DispatchQueue.main.async {
            self.panoramas = fetchedAssets
        }
    }
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let currentFetchResult = self.fetchResult,
              let changes = changeInstance.changeDetails(for: currentFetchResult) else { return }
        
        DispatchQueue.main.async {
            self.fetchResult = changes.fetchResultAfterChanges
            
            if changes.hasIncrementalChanges || changes.hasMoves {
                var updatedAssets: [PHAsset] = []
                self.fetchResult?.enumerateObjects { (asset, _, _) in
                    updatedAssets.append(asset)
                }
                
                self.panoramas = updatedAssets
            }
        }
    }

}
