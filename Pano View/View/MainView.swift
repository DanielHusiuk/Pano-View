//
//  MainView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import SwiftUI
import Photos

struct MainView: View {
    @EnvironmentObject private var fetcher: PanoramaFetcher
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("HapticState") private var isHapticEnabled = true
    
    private var isHorizontalLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                Group {
                    switch fetcher.authState {
                    case .authorized:
                        ZStack {
                            GridListView()
                            
                            if #unavailable(iOS 26.0) {
                                MainGradientView()
                                    .allowsHitTesting(false)
                            }
                        }
                        .transition(.opacity)
                        
                    case .denied, .notDetermined:
                        PhotoAccessView()
                    }
                }
                .navigationTitle("Pano View")
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .bottomBar)
                .toolbar {
                    ToolbarView()
                }
            }
            .tint(.primary)
            .transition(.opacity)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                fetcher.requestAccess()
            }
        }
    }
}
