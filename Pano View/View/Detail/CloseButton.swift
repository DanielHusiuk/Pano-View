//
//  CloseButton.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI

struct CloseButton: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("HapticState") private var isHapticEnabled = true
    
    let isLandscape: Bool
    let isHorizontalLayout: Bool
    let isInterfaceHidden: Bool
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Group {
                Button(action: {
                    dismiss()
                    if isHapticEnabled {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }) {
                    Image(systemName: "xmark")
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
            }
            .padding(.top, isLandscape ? 10 : 0)
            
        } else {
            Button(action: {
                dismiss()
                if isHapticEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)
            }
            .buttonStyle(CircularButtonStyle())
            .padding(.leading, 16)
            .padding(.top, isHorizontalLayout ? 10 : 0)
            .padding(.top, isLandscape ? 10 : 0)
            .opacity(isInterfaceHidden ? 0.0 : 1.0)
            .disabled(isInterfaceHidden)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
        }
    }
}
