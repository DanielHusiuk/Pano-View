//
//  PhotoLibraryService.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import UIKit
import Photos

final class PhotoLibraryService {
    private let manager = PHImageManager.default()
    
    func fetchImage(
        asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        deliveryMode: PHImageRequestOptionsDeliveryMode,
        completion: @escaping (UIImage?) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = deliveryMode
        options.resizeMode = .fast
        
        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
