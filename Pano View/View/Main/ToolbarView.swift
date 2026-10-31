//
//  ToolbarView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI
import Photos

struct ToolbarView: ToolbarContent {
    @EnvironmentObject private var fetcher: PanoramaFetcher
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("HapticState") private var isHapticEnabled = true
    
    private var isHorizontalLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some ToolbarContent {
        if #unavailable(iOS 26.0) {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    if isHapticEnabled {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                }
                .buttonStyle(CircularButtonStyle())
                .padding(.leading, isHorizontalLayout ? 0 : 20)
                .padding(.bottom, isHorizontalLayout ? 10 : 0)
                .opacity(fetcher.isAuthorized ? 1.0 : 0.0)
                
                Spacer()
                
                Text("panorama_count \(fetcher.panoramas.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(alignment: .center)
                    .padding(.bottom, isHorizontalLayout ? 10 : 0)
                    .shadow(color: Color(uiColor: .systemBackground), radius: 10)
                    .opacity(fetcher.isAuthorized ? 1.0 : 0.0)
                
                Spacer()
                
                Button(action: {
                    if isHapticEnabled {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                }
                .buttonStyle(CircularButtonStyle())
                .padding(.trailing, isHorizontalLayout ? 0 : 20)
                .padding(.bottom, isHorizontalLayout ? 10 : 0)
                .opacity(fetcher.isAuthorized ? 1.0 : 0.0)
            }
        }
        
        if #available(iOS 26.0, *) {
            if fetcher.isAuthorized {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        if isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                
                ToolbarSpacer(placement: .bottomBar)
                
                ToolbarItem(placement: .bottomBar) {
                    Text("panorama_count \(fetcher.panoramas.count)")
                        .frame(minWidth: 80, maxWidth: 200, alignment: .center)
                        .padding(.horizontal, 10)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                ToolbarSpacer(placement: .bottomBar)
                
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        if isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}
