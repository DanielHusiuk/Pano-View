//
//  CameraGeometry.swift
//  Pano View
//
//  Created by Daniel Husiuk on 30.10.2026.
//

import SwiftUI
import SceneKit

struct CameraGeometry {
    
    static func createCamera(
        sceneView: SCNView,
        scene: SCNScene,
        coordinator: GestureCoordinator,
        horizontalAngle: Float
    ) {
        let camera = SCNCamera()
        camera.fieldOfView = 80.0
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0)
        
        scene.rootNode.addChildNode(cameraNode)
        
        coordinator.cameraNode = cameraNode
        coordinator.camera = camera
        coordinator.horizontalAngle = horizontalAngle
        
        let panGesture = UIPanGestureRecognizer(
            target: coordinator,
            action: #selector(GestureCoordinator.handlePan(_:))
        )
        
        panGesture.delegate = coordinator
        
        let pinchGesture = UIPinchGestureRecognizer(
            target: coordinator,
            action: #selector(GestureCoordinator.handlePinch(_:))
        )
        
        pinchGesture.delegate = coordinator
        
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(pinchGesture)
    }
}
