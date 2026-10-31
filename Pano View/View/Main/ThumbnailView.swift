//
//  ThumbnailView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI
import Photos

struct ThumbnailView: View {
    @State private var image: UIImage?
    let asset: PHAsset
    private let thumbnailFetcher = ThumbnailFetcher()
    
    var body: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .clipped()
        .onAppear {
            thumbnailFetcher.fetchImage(asset: asset) { image in
                self.image = image
            }
        }
    }
}
