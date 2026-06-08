//
//  ContentView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import SwiftUI
import Photos

struct ContentView: View {
    @EnvironmentObject var fetcher: PanoramaFetcher
    let columns = [GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            Group {
                if fetcher.accessGranted {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(fetcher.panoramas, id: \.localIdentifier) { asset in
                                NavigationLink(destination: PanoramaDetailView(asset: asset)) {
                                    GeometryReader { geometry in
                                        ThumbnailView(asset: asset)
                                            .frame(width: geometry.size.width, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .frame(height: 120)
                                    .shadow(color: .black.opacity(0.3), radius: 5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        Text("App need access to your photo gallery")
                            .multilineTextAlignment(.center)
                        
                        Button("Give Access") {
                            fetcher.requestAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Pano View")
        }
        .onAppear {
            if PHPhotoLibrary.authorizationStatus() == .authorized {
                fetcher.requestAccess()
            }
        }
    }
}

struct ThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    
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
                    .overlay(ProgressView())
            }
        }
        .clipped()
        .onAppear {
            fetchImage()
        }
    }
    
    private func fetchImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        
        let targetSize = CGSize(width: 500, height: 150)
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, _ in
            DispatchQueue.main.async {
                self.image = result
            }
        }
    }
}

#Preview {
    ContentView()
}
