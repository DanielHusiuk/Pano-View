//
//  DetailViewModel.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI
import Combine
import Photos

@MainActor
final class DetailViewModel: ObservableObject {
    
    @Published var currentIndex: Int
    @Published var highResImage: UIImage?
    @Published var isLoading = true
    @Published var isInterfaceHidden = false
    
    private let photoLibraryService = PhotoLibraryService()
    
    init(currentIndex: Int) {
        self.currentIndex = currentIndex
    }
    
    func loadImage(asset: PHAsset) {
        highResImage = nil
        isLoading = true
        
        let targetSize = CGSize(width: 8192, height: 4096)
        
        photoLibraryService.fetchImage(
            asset: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            deliveryMode: .highQualityFormat
        ) { [weak self] image in
            
            self?.highResImage = image
            self?.isLoading = false
        }
    }
    
    func moveLeft() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }
    
    func moveRight(totalCount: Int) {
        guard currentIndex < totalCount - 1 else { return }
        currentIndex += 1
    }
}
