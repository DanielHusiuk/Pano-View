//
//  ThumbnailFetcher.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI
import Photos

final class ThumbnailFetcher {
    private let photoLibraryService = PhotoLibraryService()
    
    func fetchImage(
        asset: PHAsset,
        completion: @escaping (UIImage?) -> Void
    ) {
        let targetSize = CGSize(width: 500, height: 150)
        
        photoLibraryService.fetchImage(
            asset: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            deliveryMode: .opportunistic,
            completion: completion
        )
    }
}
