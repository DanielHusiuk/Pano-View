//
//  DetailView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import SwiftUI
import SceneKit
import Photos

struct DetailView: View {
    
    @StateObject private var viewModel: DetailViewModel
    @State private var isLandscape = false
    @EnvironmentObject private var fetcher: PanoramaFetcher
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(currentIndex: Int) {
        _viewModel = StateObject(wrappedValue: DetailViewModel(currentIndex: currentIndex))
    }
    
    private var asset: PHAsset? {
        guard fetcher.panoramas.indices.contains(viewModel.currentIndex) else {
            return nil
        }
        return fetcher.panoramas[viewModel.currentIndex]
    }
    
    private var formattedDate: String {
        guard let date = asset?.creationDate else {
            return "Unknown date"
        }
        return date.formatted(date: .long, time: .omitted)
    }
    
    private var formattedTime: String {
        guard let date = asset?.creationDate else {
            return "--:--"
        }
        return date.formatted(date: .omitted, time: .shortened)
    }
    
    private var isHorizontalLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height
            
            ZStack {
                Color.clear.ignoresSafeArea()
                
                if let image = viewModel.highResImage {
                    PanoramaView(image: image)
                        .id(asset?.localIdentifier)
                        .ignoresSafeArea()
                        .onReceive(
                            NotificationCenter.default.publisher(
                                for: UIDevice.orientationDidChangeNotification
                            )) { _ in }
                    
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(.primary)
                } else {
                    Text("Error loading panorama.")
                        .foregroundColor(.red)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                DetailGradientView(
                    isLandscape: landscape,
                    isInterfaceHidden: viewModel.isInterfaceHidden
                )
            }
            
            // MARK: - Button Interface
            
            .overlay(alignment: .topLeading) {
                CloseButton(
                    isLandscape: landscape,
                    isHorizontalLayout: isHorizontalLayout,
                    isInterfaceHidden: viewModel.isInterfaceHidden
                )
            }
            .overlay(alignment: .top) {
                DateButton(
                    formattedDate: formattedDate,
                    formattedTime: formattedTime,
                    isHorizontalLayout: isHorizontalLayout,
                    isLandscape: landscape,
                    isInterfaceHidden: viewModel.isInterfaceHidden
                )
            }
            .overlay(alignment: .topTrailing) {
                HideButton(
                    isLandscape: landscape,
                    isHorizontalLayout: isHorizontalLayout,
                    isInterfaceHidden: viewModel.isInterfaceHidden
                )
            }
            .overlay(alignment: .bottomLeading) {
                LeftButton(
                    isHorizontalLayout: isHorizontalLayout,
                    isInterfaceHidden: viewModel.isInterfaceHidden
                )
            }
            .overlay(alignment: .bottom) {
                FooterButton(
                    isHorizontalLayout: isHorizontalLayout,
                    isInterfaceHidden: viewModel.isInterfaceHidden
                )
            }
            .overlay(alignment: .bottomTrailing) {
                RightButton(
                    isHorizontalLayout: isHorizontalLayout,
                    isInterfaceHidden: viewModel.isInterfaceHidden
                )
            }
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if let asset {
                    viewModel.loadImage(asset: asset)
                }
            }
            .onChange(of: viewModel.currentIndex) { _ in
                if let asset {
                    viewModel.loadImage(asset: asset)
                }
            }
        }
        .environmentObject(viewModel)
    }
}

// MARK: - Extensions

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 26.0, *) {
            return
        }
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if #available(iOS 26.0, *) {
            return false
        }
        return viewControllers.count > 1
    }
}
