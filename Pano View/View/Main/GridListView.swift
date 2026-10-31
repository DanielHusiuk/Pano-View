//
//  GridListView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI
import Photos

struct GridListView: View {
    @EnvironmentObject private var fetcher: PanoramaFetcher
    let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(fetcher.groupedPanoramas) { section in
                    Section {
                        ForEach(section.assets, id: \.localIdentifier) { asset in
                            if let index = fetcher.panoramas.firstIndex(where: {
                                $0.localIdentifier == asset.localIdentifier
                            }) {
                                NavigationLink(destination: DetailView(currentIndex: index)) {
                                    GeometryReader { geometry in
                                        ThumbnailView(asset: asset)
                                            .frame(width: geometry.size.width, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .shadow(color: .black.opacity(0.3), radius: 5)
                                    }
                                    .frame(height: 120)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                    } header: {
                        Text(section.year == 0 ? "None" : String(section.year))
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                    }
                }
            }
            .padding()
        }
    }
}
