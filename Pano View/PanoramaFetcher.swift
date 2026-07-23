//
//  PanoramaFetcher.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import Foundation
import Combine
import Photos

// 1. Впровадження тристанової моделі авторизації
enum AuthState {
    case notDetermined
    case authorized
    case denied
}

struct PanoramaSection: Identifiable {
    let year: Int
    let assets: [PHAsset]
    var id: Int { year }
}

@MainActor
class PanoramaFetcher: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var panoramas: [PHAsset] = []
    @Published var groupedPanoramas: [PanoramaSection] = []
    @Published var authState: AuthState = .notDetermined
    
    private var fetchResult: PHFetchResult<PHAsset>?
    var isAuthorized: Bool {
        return authState == .authorized
    }
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        checkInitialStatus()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    private func checkInitialStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        handleAuthorization(status)
    }
    
    func requestAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        guard status == .notDetermined else {
            handleAuthorization(status)
            return
        }
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
            DispatchQueue.main.async {
                self?.handleAuthorization(newStatus)
            }
        }
    }
    
    private func handleAuthorization(_ status: PHAuthorizationStatus) {
        switch status {
        case .authorized, .limited:
            authState = .authorized
            if fetchResult == nil {
                fetchPanoramas()
            }
            
        case .denied, .restricted:
            authState = .denied
            
        case .notDetermined:
            authState = .notDetermined
            
        @unknown default:
            authState = .denied
        }
    }
    
    private func fetchPanoramas() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "(mediaSubtype & %d) != 0", PHAssetMediaSubtype.photoPanorama.rawValue)
        
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        self.fetchResult = result
        
        var fetchedAssets: [PHAsset] = []
        result.enumerateObjects { (asset, _, _) in
            fetchedAssets.append(asset)
        }
        
        self.panoramas = fetchedAssets
        self.fetchPanoramasSection()
    }
    
    private func fetchPanoramasSection() {
        let calendar = Calendar.current
        
        let groupedDict = Dictionary(grouping: panoramas) { asset -> Int in
            guard let date = asset.creationDate else { return 0 }
            return calendar.component(.year, from: date)
        }
        
        let sections = groupedDict.map { (year, assets) -> PanoramaSection in
            let sortedAssets = assets.sorted { a, b in
                guard let dateA = a.creationDate, let dateB = b.creationDate else { return false }
                return dateA > dateB
            }
            return PanoramaSection(year: year, assets: sortedAssets)
        }.sorted { $0.year > $1.year }
        
        DispatchQueue.main.async {
            self.groupedPanoramas = sections
        }
    }
    
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            guard let currentFetchResult = self.fetchResult,
                  let changes = changeInstance.changeDetails(for: currentFetchResult) else { return }
            
            self.fetchResult = changes.fetchResultAfterChanges
            
            if changes.hasIncrementalChanges || changes.hasMoves {
                var updatedAssets: [PHAsset] = []
                self.fetchResult?.enumerateObjects { (asset, _, _) in
                    updatedAssets.append(asset)
                }
                
                self.panoramas = updatedAssets
                self.fetchPanoramasSection()
            }
        }
    }
}
