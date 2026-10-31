//
//  PanoramaFetcher.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import Foundation
import Combine
import Photos

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
final class PanoramaFetcher: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    
    @Published var panoramas: [PHAsset] = []
    @Published var groupedPanoramas: [PanoramaSection] = []
    @Published var authState: AuthState = .notDetermined
    
    private var fetchResult: PHFetchResult<PHAsset>?
    var isAuthorized: Bool {
        authState == .authorized
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
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            Task { @MainActor in
                self?.handleAuthorization(status)
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
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        options.predicate = NSPredicate(
            format: "(mediaSubtype & %d) != 0",
            PHAssetMediaSubtype.photoPanorama.rawValue
        )
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        fetchResult = result
        
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        panoramas = assets
        fetchPanoramasSection()
    }
    
    private func fetchPanoramasSection() {
        let calendar = Calendar.current
        
        let grouped = Dictionary(grouping: panoramas) { asset -> Int in
            guard let date = asset.creationDate else { return 0 }
            return calendar.component(.year, from: date)
        }
        
        let sections = grouped.map { year, assets in
            PanoramaSection(
                year: year,
                assets: assets
            )
        }
            .sorted {
                $0.year > $1.year
            }
        groupedPanoramas = sections
    }
    
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in
            guard let self,
                  let currentResult = self.fetchResult,
                  let changes = changeInstance.changeDetails(for: currentResult)
                    else {
                return
            }
            
            self.fetchResult = changes.fetchResultAfterChanges
            
            if changes.hasIncrementalChanges || changes.hasMoves {
                var assets: [PHAsset] = []
                
                self.fetchResult?.enumerateObjects { asset, _, _ in
                    assets.append(asset)
                }
                
                self.panoramas = assets
                self.fetchPanoramasSection()
            }
        }
    }
}
