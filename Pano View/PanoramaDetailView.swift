//
//  PanoramaDetailView.swift
//  Pano View
//
//  Created by Daniel Husiuk on 21.05.2026.
//

import SwiftUI
import SceneKit
import Photos

struct SceneKitPanoramaView: UIViewRepresentable {
    let image: UIImage
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .black
        
        let scene = SCNScene()
        let radius: CGFloat = 10.0
        let aspectRatio = image.size.width / image.size.height
        let height = (2 * .pi * radius) / aspectRatio
        let cylinder = SCNCylinder(radius: radius, height: height)
        
        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = image
        sideMaterial.isDoubleSided = true
        sideMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1)
        sideMaterial.diffuse.wrapS = .repeat
        
        let clearMaterial = SCNMaterial()
        clearMaterial.diffuse.contents = UIColor.clear
        cylinder.materials = [sideMaterial, clearMaterial, clearMaterial]
        
        let cylinderNode = SCNNode(geometry: cylinder)
        cylinderNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(cylinderNode)
        
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        context.coordinator.cameraNode = cameraNode
        
        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        sceneView.addGestureRecognizer(panGesture)
        
        sceneView.scene = scene
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        
    }
    
    
    // MARK: - Physics & Gesture Coordinator
    
    class Coordinator: NSObject {
        var cameraNode: SCNNode?
        private var displayLink: CADisplayLink?
        private var angularVelocity: Float = 0
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let camera = cameraNode else { return }
            
            switch gesture.state {
            case .began:
                displayLink?.invalidate()
                displayLink = nil
                angularVelocity = 0
                
            case .changed:
                let translation = gesture.translation(in: gesture.view)
                let panSensitivity: Float = 0.004
                
                camera.eulerAngles.y += Float(translation.x) * panSensitivity
                gesture.setTranslation(.zero, in: gesture.view)
                
            case .ended, .cancelled:
                let velocity = gesture.velocity(in: gesture.view)
                self.angularVelocity = Float(velocity.x) * 0.0001
                startDeceleration()
                
            default:
                break
            }
        }
        
        private func startDeceleration() {
            displayLink = CADisplayLink(target: self, selector: #selector(updatePhysics))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        @objc private func updatePhysics() {
            guard let camera = cameraNode else { return }
            camera.eulerAngles.y += angularVelocity
            angularVelocity *= 0.7
            
            if abs(angularVelocity) < 0.0001 {
                displayLink?.invalidate()
                displayLink = nil
            }
        }
    }
}

struct PanoramaDetailView: View {
    let asset: PHAsset
    @State private var highResImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let image = highResImage {
                SceneKitPanoramaView(image: image)
                    .ignoresSafeArea()
            } else if isLoading {
                ProgressView("Loading panorama...")
                    .tint(.white)
                    .foregroundColor(.white)
            } else {
                Text("Error loading panorama.")
                    .foregroundColor(.red)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            loadHighResImage()
        }
    }
    
    private func loadHighResImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { result, _ in
            DispatchQueue.main.async {
                self.highResImage = result
                self.isLoading = false
            }
        }
    }
}
