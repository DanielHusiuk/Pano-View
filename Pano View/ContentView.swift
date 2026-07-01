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
    let columns = [GridItem(.adaptive(minimum: 260))]
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationStack {
                Group {
                    if fetcher.accessGranted {
                        ZStack {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(fetcher.panoramas, id: \.localIdentifier) { asset in
                                        NavigationLink(destination: PanoramaDetailView(asset: asset)) {
                                            GeometryReader { geometry in
                                                ThumbnailView(asset: asset)
                                                    .frame(width: geometry.size.width, height: 120)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .shadow(color: .black.opacity(0.3), radius: 5)
                                            }
                                            .frame(height: 120)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                            }
                            
                            GeometryReader { value in
                                let isLandscape = value.size.width > value.size.height
                                if #unavailable(iOS 26.0) {
                                    VStack {
                                        Rectangle()
                                            .fill(.background)
                                            .frame(height: isLandscape ? 50 : 150)
                                            .mask(
                                                LinearGradient(
                                                    stops: [
                                                        .init(color: .clear, location: 0.0),
                                                        .init(color: .black, location: 0.8)
                                                    ],
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                                .blendMode(.multiply)
                                            )
                                            .allowsHitTesting(false)
                                        Spacer()
                                    }
                                    .ignoresSafeArea()
                                }
                            }
                            
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(.background)
                                    .frame(height: 50)
                                    .mask(
                                        LinearGradient(
                                            stops: [
                                                .init(color: .clear, location: 0),
                                                .init(color: .black, location: 0.8)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .blendMode(.multiply)
                                    )
                                    .allowsHitTesting(false)
                            }
                            .offset(y: 10)
                            .ignoresSafeArea()
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
                .toolbarBackground(.hidden, for: .navigationBar)
            }
            .tint(.primary)
            
            Button(action: {
                
            }) {
                if #available(iOS 26.0, *) {
                    Image(systemName: "gear")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .glassEffect()
                } else {
                    Image(systemName: "gear")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 5)
                }
            }
            .padding(.trailing, 16)
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
