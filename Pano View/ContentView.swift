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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    
    let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]
    var isHorizontalLayout: Bool {
        horizontalSizeClass == .regular
        
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationStack {
                Group {
                    if fetcher.accessGranted {
                        ZStack {
                            ScrollView {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(fetcher.groupedPanoramas) { section in
                                        Section {
                                            ForEach(section.assets, id: \.localIdentifier) { asset in
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
                                            
                                        } header: {
                                            Text(section.year == 0 ? "None" : String(section.year))
                                                .font(.title2.bold())
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.top, 16)
                                        }
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
                                
                                
                                VStack {
                                    if #unavailable(iOS 26) {
                                        Spacer()
                                        Rectangle()
                                            .fill(.background)
                                            .frame(height: isLandscape ? 80 : 100)
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
                                }
                                .offset(y: 20)
                                .ignoresSafeArea()
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Text("To view your captured panoramas provide access to your photo gallery")
                                .multilineTextAlignment(.center)
                                .font(.system(size: 18, weight: .medium))
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            
                            Button("Give Access") {
                                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                                if status == .denied || status == .restricted {
                                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                } else {
                                    fetcher.requestAccess()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .clipShape(.capsule)
                            .font(.system(size: 20, weight: .semibold))
                            .backgroundStyle(.foreground)
                            .foregroundStyle(.background)
                            .shadow(color: .black.opacity(0.2), radius: 10)
                        }
                        .frame(alignment: .center)
                        .animation(.easeInOut(duration: 0.1), value: fetcher.accessGranted)
                    }
                }
                .navigationTitle("Pano View")
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .bottomBar)
                .toolbar {
                    if #unavailable(iOS 26.0) {
                        ToolbarItem(placement: .bottomBar) {
                            Button(action: {
                            }) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.clear)
                            .background(.ultraThinMaterial)
                            .frame(width: 44, height: 44 )
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 5)
                            .padding(.leading, isHorizontalLayout ? 0 : 20)
                            .padding(.bottom, isHorizontalLayout ? 10 : 0)
                            .opacity(fetcher.accessGranted ? 1.0 : 0.0)
                        }
                        
                        ToolbarItem(placement: .bottomBar) {
                            Button(action: {
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.clear)
                            .background(.ultraThinMaterial)
                            .frame(width: 44, height: 44 )
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 5)
                            .padding(.trailing, isHorizontalLayout ? 0 : 20)
                            .padding(.bottom, isHorizontalLayout ? 10 : 0)
                            .opacity(fetcher.accessGranted ? 1.0 : 0.0)
                        }
                    }
                    
                    if #available(iOS 26.0, *) {
                        if fetcher.accessGranted {
                            ToolbarItem(placement: .bottomBar) {
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "arrow.up.arrow.down")
                                }
                            }
                            
                            ToolbarSpacer(placement: .bottomBar)
                            
                            ToolbarItem(placement: .bottomBar) {
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "gear")
                                }
                            }
                        }
                    }
                }
            }
            .tint(.primary)
            .animation(.easeInOut(duration: 0.3), value: fetcher.accessGranted)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
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
