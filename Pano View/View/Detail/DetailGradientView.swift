//
//  DetailGradientView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI

struct DetailGradientView: View {
    let isLandscape: Bool
    var isInterfaceHidden: Bool
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(.black.opacity(0.5))
                .frame(height: isLandscape ? 40 : 80)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black, location: 1.0)
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
        .opacity(isInterfaceHidden ? 0.0 : 1.0)
        .disabled(isInterfaceHidden)
        .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
        
        VStack {
            Spacer()
            Rectangle()
                .fill(.black.opacity(0.5))
                .frame(height: isLandscape ? 60 : 80)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blendMode(.multiply)
                )
                .allowsHitTesting(false)
        }
        .offset(y: 20)
        .ignoresSafeArea()
        .opacity(isInterfaceHidden ? 0.0 : 1.0)
        .disabled(isInterfaceHidden)
        .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
    }
}
