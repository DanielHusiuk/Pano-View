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
    let size: CGSize
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .black
        sceneView.antialiasingMode = .none
        
        let scene = SCNScene()
        let aspectRatio = Float(image.size.width / image.size.height)
        
        //panorama
        let arcGeometry = createPanoramaArc(aspectRatio: aspectRatio, radius: 10.0, padding: 0.0)
        let theta = arcGeometry.value(forKey: "theta") as? Float ?? .pi
        let material = SCNMaterial()
        material.diffuse.contents = image.cgImage
        material.isDoubleSided = false
        material.diffuse.mipFilter = .linear
        
        material.transparent.contents = createCornerMask(aspectRatio: aspectRatio)
        arcGeometry.materials = [material]
        
        let arcNode = SCNNode(geometry: arcGeometry)
        arcNode.position = SCNVector3(0, 0, 0)
        arcNode.renderingOrder = 1
        scene.rootNode.addChildNode(arcNode)
        
        //shadow
        let shadowGeometry = createPanoramaArc(aspectRatio: aspectRatio, radius: 10.2, padding: 2.5)
        let shadowMaterial = SCNMaterial()
        
        shadowMaterial.diffuse.contents = createDropShadow(aspectRatio: aspectRatio, theta: theta)
        shadowMaterial.isDoubleSided = false
        shadowMaterial.writesToDepthBuffer = false
        shadowGeometry.materials = [shadowMaterial]
        
        let shadowNode = SCNNode(geometry: shadowGeometry)
        shadowNode.position = SCNVector3(0, 0, 0)
        shadowNode.renderingOrder = 0
        scene.rootNode.addChildNode(shadowNode)
        
        //background
        let backgroundGeometry = createPanoramaArc(aspectRatio: aspectRatio, radius: 15.0, expandScale: 6)
        let tinySize = CGSize(width: 200, height: 200 / CGFloat(aspectRatio))
        let renderer = UIGraphicsImageRenderer(size: tinySize)
        let tinyImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: tinySize))
        }
        
        var blurryImage = tinyImage
        if let ciImage = CIImage(image: tinyImage), let blurFilter = CIFilter(name: "CIGaussianBlur") {
            blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
            blurFilter.setValue(15.0, forKey: kCIInputRadiusKey)
            
            let context = CIContext()
            if let output = blurFilter.outputImage,
               let cgImage = context.createCGImage(output, from: ciImage.extent) {
                blurryImage = UIImage(cgImage: cgImage)
            }
        }
        
        let backgroundMaterial = SCNMaterial()
        backgroundMaterial.diffuse.contents = blurryImage
        backgroundMaterial.isDoubleSided = false
        backgroundMaterial.writesToDepthBuffer = false
        
        backgroundMaterial.diffuse.intensity = 0.5
        backgroundGeometry.materials = [backgroundMaterial]
        
        let backgroundNode = SCNNode(geometry: backgroundGeometry)
        backgroundNode.position = SCNVector3(0, 0, 0)
        backgroundNode.renderingOrder = -1
        scene.rootNode.addChildNode(backgroundNode)
        
        //camera
        let camera = SCNCamera()
        camera.fieldOfView = 80.0
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        context.coordinator.cameraNode = cameraNode
        context.coordinator.camera = camera
        context.coordinator.horizontalAngle = arcGeometry.value(forKey: "theta") as? Float ?? .pi
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        
        sceneView.addGestureRecognizer(panGesture)
        sceneView.addGestureRecognizer(pinchGesture)
        
        sceneView.scene = scene
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        let newSize = size
        guard newSize.height > 0 else { return }
        
        if context.coordinator.currentViewSize != newSize {
            context.coordinator.currentViewSize = newSize
            context.coordinator.animateCameraBounds()
        }
    }
    
    private func createPanoramaArc(aspectRatio: Float, radius: Float = 10.0, padding: Float = 0.0, expandScale: Float = 1.0) -> SCNGeometry {
        let verticalFOVRadians: Float = 65.0 * .pi / 180.0
        
        let baseHeight = 2.0 * radius * tan(verticalFOVRadians / 2.0) * expandScale
        let baseArcLength = baseHeight * aspectRatio
        
        let height = baseHeight + padding
        let arcLength = baseArcLength + padding
        
        let theta = (arcLength / radius) * expandScale
        let finalTheta = min(theta, Float.pi * 2.0)
        
        let segments = Int(max(50, finalTheta * 20))
        let angleStep = finalTheta / Float(segments)
        let startAngle = -finalTheta / 2.0
        
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
        geometry.setValue(finalTheta, forKey: "theta")
        return geometry
    }
    
    
    //MARK: - Corners & Shadow
    
    private func createCornerMask(aspectRatio: Float) -> UIImage {
        let width: CGFloat = 1024
        let height = width / CGFloat(aspectRatio)
        let size = CGSize(width: width, height: height)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.white.setFill()
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: width * 0.01)
            path.fill()
        }
    }
    
    private func createDropShadow(aspectRatio: Float, theta: Float) -> UIImage {
        let width: CGFloat = 1024
        let size = CGSize(width: width, height: width * 0.5)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let rawShadow = renderer.image { context in
            let shadowWidth = size.width * CGFloat(theta / (.pi * 2.0))
            let rect = CGRect(x: (size.width - shadowWidth) / 2, y: size.height * 0.1, width: shadowWidth, height: size.height * 0.8)
            
            let path = UIBezierPath(roundedRect: rect, cornerRadius: width * 0.02)
            UIColor.black.setFill()
            path.fill()
        }
        
        guard let ciImage = CIImage(image: rawShadow),
              let blurFilter = CIFilter(name: "CIGaussianBlur") else { return rawShadow }
        
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(15.0, forKey: kCIInputRadiusKey)
        
        let context = CIContext()
        if let output = blurFilter.outputImage,
           let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return rawShadow
    }
    
    
    // MARK: - Gesture Coordinator
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var cameraNode: SCNNode?
        var camera: SCNCamera?
        
        var horizontalAngle: Float = 0
        private var initialFOV: CGFloat = 80.0
        private var displayLink: CADisplayLink?
        
        private var yawVelocity: Float = 0
        private var pitchVelocity: Float = 0
        private var fovVelocity: CGFloat = 0
        var currentViewSize: CGSize = .zero
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if #available(iOS 26.0, *) {
                return true
            }
            
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = panGesture.velocity(in: panGesture.view)
            let location = panGesture.location(in: panGesture.view)
            
            if location.x < 40 && velocity.x > 0 {
                return false
            }
            return true
        }
        
        private func getCameraPhysics() -> (maxYaw: Float, maxPitch: Float, yawSens: Float, pitchSens: Float) {
            guard currentViewSize.height > 0, let camera = camera else { return (0, 0, 0, 0) }
            
            let aspect = Float(currentViewSize.width / currentViewSize.height)
            let verticalFovRadians = Float(camera.fieldOfView) * .pi / 180.0
            let horizontalFovRadians = 2.0 * atan(tan(verticalFovRadians / 2.0) * aspect)
            let baseMarginPixels: Float = 50.0
            
            let radPerPixel = horizontalFovRadians / Float(currentViewSize.width)
            let extraMarginRadians = baseMarginPixels * radPerPixel
            let baseMaxYaw = (horizontalAngle / 2.0) - (horizontalFovRadians / 2.0)
            let maxYaw = max(0, baseMaxYaw + extraMarginRadians)
            let maxPitch: Float = 25.0 * .pi / 180.0
            
            let yawSens = horizontalFovRadians / Float(currentViewSize.width)
            let pitchSens = verticalFovRadians / Float(currentViewSize.height)
            return (maxYaw, maxPitch, yawSens, pitchSens)
        }
        
        func animateCameraBounds() {
            guard let node = cameraNode else { return }
            let physics = getCameraPhysics()
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            
            node.eulerAngles.y = min(max(node.eulerAngles.y, -physics.maxYaw), physics.maxYaw)
            node.eulerAngles.x = min(max(node.eulerAngles.x, -physics.maxPitch), physics.maxPitch)
            SCNTransaction.commit()
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let node = cameraNode, let view = gesture.view else { return }
            currentViewSize = view.bounds.size
            
            let physics = getCameraPhysics()
            
            switch gesture.state {
            case .began:
                displayLink?.invalidate()
                displayLink = nil
                yawVelocity = 0
                pitchVelocity = 0
                fovVelocity = 0
                
            case .changed:
                let translation = gesture.translation(in: view)
                
                var newYaw = node.eulerAngles.y + Float(translation.x) * physics.yawSens
                newYaw = min(max(newYaw, -physics.maxYaw), physics.maxYaw)
                
                var newPitch = node.eulerAngles.x + Float(translation.y) * physics.pitchSens
                newPitch = min(max(newPitch, -physics.maxPitch), physics.maxPitch)
                
                node.eulerAngles.y = newYaw
                node.eulerAngles.x = newPitch
                gesture.setTranslation(.zero, in: view)
                
            case .ended, .cancelled:
                let velocity = gesture.velocity(in: view)
                yawVelocity = Float(velocity.x) * physics.yawSens / 60.0
                pitchVelocity = Float(velocity.y) * physics.pitchSens / 60.0
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
                newFOV = max(20.0, min(newFOV, 80.0))
                camera.fieldOfView = newFOV
                
                if let node = cameraNode {
                    let physics = getCameraPhysics()
                    node.eulerAngles.y = min(max(node.eulerAngles.y, -physics.maxYaw), physics.maxYaw)
                    node.eulerAngles.x = min(max(node.eulerAngles.x, -physics.maxPitch), physics.maxPitch)
                }
                
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
            guard let node = cameraNode, let camera = camera else { return }
            
            let physics = getCameraPhysics()
            
            let newYaw = node.eulerAngles.y + yawVelocity
            let newPitch = node.eulerAngles.x + pitchVelocity
            let newFov = camera.fieldOfView + fovVelocity
            
            let clampedYaw = min(max(newYaw, -physics.maxYaw), physics.maxYaw)
            let clampedPitch = min(max(newPitch, -physics.maxPitch), physics.maxPitch)
            let clampedFov = max(20.0, min(newFov, 80.0))
            
            if clampedYaw != newYaw { yawVelocity = 0 }
            if clampedPitch != newPitch { pitchVelocity = 0 }
            if clampedFov != newFov { fovVelocity = 0 }
            
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


//MARK: - PanoramaDetailView

struct PanoramaDetailView: View {
    let asset: PHAsset
    @State private var highResImage: UIImage?
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss
    
    private var isBackButtonHidden: Bool {
        if #available(iOS 26.0, *) {
            return false
        } else {
            return true
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let image = highResImage {
                GeometryReader { geometry in
                    SceneKitPanoramaView(image: image, size: geometry.size)
                }
                .ignoresSafeArea()
                .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in }
            } else if isLoading {
                ProgressView("Loading panorama...")
                    .tint(.white)
                    .foregroundColor(.white)
            } else {
                Text("Error loading panorama.")
                    .foregroundColor(.red)
            }
        }
        .overlay(alignment: .topLeading) {
            if isBackButtonHidden {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 5)
                }
                .padding(.leading, 16)
            }
        }
        .navigationBarBackButtonHidden(isBackButtonHidden)
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
        let maxSize = CGSize(width: 8192, height: 4096)
        
        manager.requestImage(for: asset, targetSize: maxSize, contentMode: .aspectFit, options: options) { result, _ in
            DispatchQueue.main.async {
                self.highResImage = result
                self.isLoading = false
            }
        }
    }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 26.0, *) {
            return
        }
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if #available(iOS 26.0, *) {
            return false
        }
        return viewControllers.count > 1
    }
}
