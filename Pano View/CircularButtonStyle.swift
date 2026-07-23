//
//  CircularButtonStyle.swift
//  Pano View
//
//  Created by Daniel Husiuk on 23.07.2026.
//

import SwiftUI

struct CircularButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    var backgroundStyle: AnyShapeStyle = AnyShapeStyle(.ultraThinMaterial)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(backgroundStyle)
            .overlay {
                if configuration.isPressed {
                    if colorScheme == .light {
                        Color.black.opacity(0.2)
                    } else {
                        Color.white.opacity(0.2)
                    }
                }
            }
            .clipShape(Circle())
            .contentShape(Circle())
            .shadow(color: .black.opacity(0.2), radius: 5)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
