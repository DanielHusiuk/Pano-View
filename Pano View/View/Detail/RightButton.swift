//
//  RightButton.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI

struct RightButton: View {
    @EnvironmentObject private var viewModel: DetailViewModel
    @EnvironmentObject private var fetcher: PanoramaFetcher
    @AppStorage("HapticState") private var isHapticEnabled = true
    
    let isHorizontalLayout: Bool
    let isInterfaceHidden: Bool
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: {
                guard viewModel.currentIndex < fetcher.panoramas.count - 1 else { return }
                viewModel.currentIndex += 1
                if isHapticEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .regular))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive())
            .padding(.trailing)
            .opacity(isInterfaceHidden ? 0.0 : 1.0)
            .disabled(isInterfaceHidden)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
            
        } else {
            Button(action: {
                guard viewModel.currentIndex < fetcher.panoramas.count - 1 else { return }
                viewModel.currentIndex += 1
                if isHapticEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)
            }
            .buttonStyle(CircularButtonStyle())
            .padding(.trailing, 16)
            .padding(.bottom, isHorizontalLayout ? 10 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .opacity(isInterfaceHidden ? 0.0 : 1.0)
            .disabled(isInterfaceHidden)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
        }
    }
}
