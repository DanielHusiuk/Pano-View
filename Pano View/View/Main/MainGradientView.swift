//
//  MainGradientView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI

struct MainGradientView: View {
    
    var body: some View {
        GeometryReader { value in
            let isLandscape = value.size.width > value.size.height
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
            
            VStack {
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
            .offset(y: 20)
            .ignoresSafeArea()
        }
    }
}
