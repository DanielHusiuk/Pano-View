//
//  HideButton.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI

struct HideButton: View {
    @EnvironmentObject private var viewModel: DetailViewModel
    @AppStorage("HapticState") private var isHapticEnabled = true
    
    let isLandscape: Bool
    let isHorizontalLayout: Bool
    var isInterfaceHidden: Bool
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Group {
                Button(action: {
                    viewModel.isInterfaceHidden.toggle()
                    if isHapticEnabled {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }) {
                    Image(systemName: isInterfaceHidden ? "eye" : "eye.slash")
                        .font(.system(size: 20, weight: .regular))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                }
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive())
                .padding(.trailing)
                .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
            }
            .padding(.top, isLandscape ? 10 : 0)
            
        } else {
            Button(action: {
                viewModel.isInterfaceHidden.toggle()
                if isHapticEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }) {
                Image(systemName: isInterfaceHidden ? "eye" : "eye.slash")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary.opacity(isInterfaceHidden ? 0.1 : 1.0))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(CircularButtonStyle(
                backgroundStyle: AnyShapeStyle(
                    .ultraThinMaterial.opacity(isInterfaceHidden ? 0.0 : 1.0)
                )
            )
            )
            .padding(.trailing, 16)
            .padding(.top, isHorizontalLayout ? 10 : 0)
            .padding(.top, isLandscape ? 10 : 0)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
        }
    }
}
