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
        let aspectRatio = Float(image.size.width / image.size.height)
        let arcGeometry = createPanoramaArc(aspectRatio: aspectRatio)
        
        let material = SCNMaterial()
        material.diffuse.contents = image
        
        material.isDoubleSided = false
        arcGeometry.materials = [material]
        
        let arcNode = SCNNode(geometry: arcGeometry)
        arcNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(arcNode)
        
        let camera = SCNCamera()
        camera.fieldOfView = 65.0
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        context.coordinator.cameraNode = cameraNode
        context.coordinator.camera = camera
        context.coordinator.horizontalAngle = arcGeometry.value(forKey: "theta") as? Float ?? .pi
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(pinchGesture)
        
        sceneView.scene = scene
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    private func createPanoramaArc(aspectRatio: Float) -> SCNGeometry {
        let radius: Float = 10.0
        let verticalFOVRadians: Float = 65.0 * .pi / 180.0
        
        let height = 2.0 * radius * tan(verticalFOVRadians / 2.0)
        let arcLength = height * aspectRatio
        let theta = arcLength / radius
        
        let segments = Int(max(50, theta * 20))
        let angleStep = theta / Float(segments)
        let startAngle = -theta / 2.0
        
        var vertices: [SCNVector3] = []
        var uvs: [CGPoint] = []
        var indices: [UInt32] = []
        
        for i in 0...segments {
            let currentAngle = startAngle + Float(i) * angleStep
            let x = radius * sin(currentAngle)
            let z = -radius * cos(currentAngle)
            
            vertices.append(SCNVector3(x, height / 2.0, z))
            uvs.append(CGPoint(x: CGFloat(i) / CGFloat(segments), y: 0.0))
            
            vertices.append(SCNVector3(x, -height / 2.0, z))
            uvs.append(CGPoint(x: CGFloat(i) / CGFloat(segments), y: 1.0))
        }
        
        for i in 0..<UInt32(segments) {
            let top1 = i * 2
            let bot1 = i * 2 + 1
            let top2 = (i + 1) * 2
            let bot2 = (i + 1) * 2 + 1
            
            indices.append(contentsOf: [top1, bot1, top2])
            indices.append(contentsOf: [bot1, bot2, top2])
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let uvSource = SCNGeometrySource(textureCoordinates: uvs)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        let geometry = SCNGeometry(sources: [vertexSource, uvSource], elements: [element])
        geometry.setValue(theta, forKey: "theta")
        return geometry
    }
    
    
    // MARK: - Gesture Coordinator
    
    class Coordinator: NSObject {
        var cameraNode: SCNNode?
        var camera: SCNCamera?
        var horizontalAngle: Float = 0
        private var initialFOV: CGFloat = 65.0
        
        private var displayLink: CADisplayLink?
        private var yawVelocity: Float = 0
        private var pitchVelocity: Float = 0
        private var fovVelocity: CGFloat = 0
        private var currentViewSize: CGSize = .zero
        private let sensitivityMultiplier: Float = 1.4
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let node = cameraNode,
                  let camera = camera,
                  let view = gesture.view else { return }
            
            currentViewSize = view.bounds.size
            
            let currentVerticalFovRadians = Float(camera.fieldOfView) * .pi / 180
            let currentHorizontalFovRadians = currentVerticalFovRadians * Float(currentViewSize.width / currentViewSize.height)
            
            let yawSensitivity = currentHorizontalFovRadians / Float(currentViewSize.width)
            let pitchSensitivity = currentVerticalFovRadians / Float(currentViewSize.height)
            
            let maxYaw = max(0, (horizontalAngle / 2.0) - (currentHorizontalFovRadians / 2.0))
            let maxPitch: Float = 20.0 * .pi / 180.0
            
            switch gesture.state {
            case .began:
                displayLink?.invalidate()
                displayLink = nil
                
                yawVelocity = 0
                pitchVelocity = 0
                fovVelocity = 0
                
            case .changed:
                let translation = gesture.translation(in: view)
                
                var newYaw = node.eulerAngles.y + Float(translation.x) * yawSensitivity
                newYaw = min(max(newYaw, -maxYaw), maxYaw)
                
                var newPitch = node.eulerAngles.x + Float(translation.y) * pitchSensitivity
                newPitch = min(max(newPitch, -maxPitch), maxPitch)
                
                node.eulerAngles.y = newYaw
                node.eulerAngles.x = newPitch
                gesture.setTranslation(.zero, in: view)
                
            case .ended, .cancelled:
                let velocity = gesture.velocity(in: view)
                yawVelocity = Float(velocity.x) * yawSensitivity / 60.0
                pitchVelocity = Float(velocity.y) * pitchSensitivity / 60.0
                startDeceleration()
                
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let camera = camera else { return }
            
            switch gesture.state {
            case .began:
                initialFOV = camera.fieldOfView
                displayLink?.invalidate()
                displayLink = nil
                
                yawVelocity = 0
                pitchVelocity = 0
                fovVelocity = 0
                
            case .changed:
                var newFOV = initialFOV / gesture.scale
                newFOV = max(20.0, min(newFOV, 90.0))
                camera.fieldOfView = newFOV
                
            case .ended, .cancelled:
                fovVelocity = -gesture.velocity * 0.5 / 60.0
                startDeceleration()
                
            default:
                break
            }
        }
        
        private func startDeceleration() {
            if displayLink == nil {
                displayLink = CADisplayLink(target: self, selector: #selector(updatePhysics))
                displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
                displayLink?.add(to: .main, forMode: .common)
            }
        }
        
        @objc private func updatePhysics() {
            guard let node = cameraNode,
                  let camera = camera else { return }
            
            var newYaw = node.eulerAngles.y + yawVelocity
            var newPitch = node.eulerAngles.x + pitchVelocity
            
            let currentVerticalFov = Float(camera.fieldOfView) * .pi / 180.0
            let currentHorizontalFov = currentVerticalFov * Float(currentViewSize.width / currentViewSize.height)
            let maxYaw = max(0, (horizontalAngle / 2.0) - (currentHorizontalFov / 2.0))
            let maxPitch: Float = 20.0 * .pi / 180.0
            let newFov = camera.fieldOfView + fovVelocity
            
            let clampedYaw = min(max(newYaw, -maxYaw), maxYaw)
            let clampedPitch = min(max(newPitch, -maxPitch), maxPitch)
            let clampedFov = max(20.0, min(newFov, 90.0))
            
            if clampedYaw != newYaw {
                yawVelocity = 0
            }
            if clampedPitch != newPitch {
                pitchVelocity = 0
            }
            if clampedFov != newFov {
                fovVelocity = 0
            }

            node.eulerAngles.y = clampedYaw
            node.eulerAngles.x = clampedPitch
            camera.fieldOfView = clampedFov
            yawVelocity *= 0.95
            pitchVelocity *= 0.95
            fovVelocity *= 0.85
            
            if abs(yawVelocity) < 0.0001 && abs(pitchVelocity) < 0.0001 && abs(fovVelocity) < 0.0001 {
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
