//
//  PanoramaView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI
import SceneKit

struct PanoramaView: UIViewRepresentable {
    let image: UIImage
    
    func makeCoordinator() -> GestureCoordinator {
        GestureCoordinator()
    }
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView(frame: .zero)
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .black
        sceneView.antialiasingMode = .none
        
        let scene = SCNScene()
        let aspectRatio = Float(image.size.width / image.size.height)
        sceneView.scene = scene
        
        ArcGeometry.createArcGeometry(
            image: image,
            aspectRatio: aspectRatio,
            scene: scene
        )
        
        ShadowGeometry.createShadow(
            aspectRatio: aspectRatio,
            scene: scene
        )
        
        BackgroundGeometry.createBackground(
            image: image,
            aspectRatio: aspectRatio,
            scene: scene
        )
        
        CameraGeometry.createCamera(
            sceneView: sceneView,
            scene: scene,
            coordinator: context.coordinator,
            horizontalAngle: ArcGeometry.calculateAngle(
                aspectRatio: aspectRatio
            )
        )
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        let newSize = uiView.bounds.size
        guard newSize.height > 0 else { return }
        
        if context.coordinator.currentViewSize != newSize {
            context.coordinator.currentViewSize = newSize
            context.coordinator.animateCameraBounds()
        }
    }
}
