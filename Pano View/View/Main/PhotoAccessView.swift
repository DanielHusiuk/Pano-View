//
//  PhotoAccessView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI
import Photos

struct PhotoAccessView: View {
    @EnvironmentObject private var fetcher: PanoramaFetcher
    
    var body: some View {
        VStack(spacing: 20) {
            Text("To view your captured panoramas provide access to your photo gallery")
                .multilineTextAlignment(.center)
                .font(.system(size: 18, weight: .medium))
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            
            Button("Give Access") {
                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                if status == .denied || status == .restricted {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } else {
                    fetcher.requestAccess()
                }
            }
            .buttonStyle(.borderedProminent)
            .clipShape(.capsule)
            .font(.system(size: 20, weight: .semibold))
            .backgroundStyle(.foreground)
            .foregroundStyle(.background)
            .shadow(color: .black.opacity(0.2), radius: 10)
        }
        .frame(alignment: .center)
        .transition(.opacity)
    }
}
