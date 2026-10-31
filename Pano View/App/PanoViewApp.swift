//
//  PanoViewApp.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import SwiftUI

@main
struct PanoViewApp: App {
    @StateObject private var panoramaFetcher = PanoramaFetcher()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(panoramaFetcher)
        }
    }
}
