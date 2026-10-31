//
//  FooterButton.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI

struct FooterButton: View {
    @EnvironmentObject private var viewModel: DetailViewModel
    @EnvironmentObject private var fetcher: PanoramaFetcher
    
    let isHorizontalLayout: Bool
    let isInterfaceHidden: Bool
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Button {
                
            } label: {
                Text("\(viewModel.currentIndex + 1) of \(fetcher.panoramas.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 5)
            }
            .frame(minWidth: 60, maxWidth: 100, minHeight: 44, maxHeight: 44, alignment: .center)
            .glassEffect(.regular.interactive())
            .opacity(isInterfaceHidden ? 0.0 : 1.0)
            .disabled(isInterfaceHidden)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
            
        } else {
            Button {
                
            } label: {
                Text("\(viewModel.currentIndex + 1) of \(fetcher.panoramas.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(alignment: .center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 5)
            }
            .allowsHitTesting(false)
            .buttonStyle(.borderedProminent)
            .tint(.clear)
            .foregroundStyle(.primary)
            .background(.ultraThinMaterial, in: Capsule())
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 5)
            .padding(.bottom, isHorizontalLayout ? 10 : 0)
            .opacity(isInterfaceHidden ? 0.0 : 1.0)
            .disabled(isInterfaceHidden)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
        }
    }
}
