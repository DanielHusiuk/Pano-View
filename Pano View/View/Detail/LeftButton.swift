//
//  LeftButton.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI

struct LeftButton: View {
    @EnvironmentObject private var viewModel: DetailViewModel
    @AppStorage("HapticState") private var isHapticEnabled = true
    
    let isHorizontalLayout: Bool
    let isInterfaceHidden: Bool
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: {
                guard viewModel.currentIndex > 0 else { return }
                viewModel.currentIndex -= 1
                if isHapticEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .regular))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
            }
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive())
            .padding(.leading)
            .opacity(isInterfaceHidden ? 0.0 : 1.0)
            .disabled(isInterfaceHidden)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
            
        } else {
            Button(action: {
                guard viewModel.currentIndex > 0 else { return }
                viewModel.currentIndex -= 1
                if isHapticEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)
            }
            .buttonStyle(CircularButtonStyle())
            .padding(.leading, 16)
            .padding(.bottom, isHorizontalLayout ? 10 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .opacity(isInterfaceHidden ? 0.0 : 1.0)
            .disabled(isInterfaceHidden)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
        }
    }
}
