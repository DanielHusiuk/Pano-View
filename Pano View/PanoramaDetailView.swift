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
        
        //MARK: - Panorama
        
        let arcGeometry = createPanoramaArc(aspectRatio: aspectRatio, radius: 10.0, padding: 0.0)
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
        let shadowGeometry = createPanoramaArc(aspectRatio: aspectRatio, radius: 10.2, padding: 1.8)
        let shadowMaterial = SCNMaterial()
        
        shadowMaterial.diffuse.contents = createDropShadow(aspectRatio: aspectRatio)
        shadowMaterial.isDoubleSided = false
        shadowMaterial.writesToDepthBuffer = false
        shadowGeometry.materials = [shadowMaterial]
        
        let shadowNode = SCNNode(geometry: shadowGeometry)
        shadowNode.position = SCNVector3(0, 0, 0)
        shadowNode.renderingOrder = 0
        scene.rootNode.addChildNode(shadowNode)
        
        //MARK: - Background
        
        let backgroundGeometry = createPanoramaArc(aspectRatio: aspectRatio, radius: 15.0, expandScale: 4)
        let tinySize = CGSize(width: 300, height: 300 / CGFloat(aspectRatio))
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
        
        //MARK: - Camera
        
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
    
    //MARK: - Create Arc
    
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
        let height: CGFloat = 512
        let width = height * CGFloat(aspectRatio)
        let size = CGSize(width: width, height: height)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.white.setFill()
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: height * 0.04)
            path.fill()
        }
    }
    
    private func createDropShadow(aspectRatio: Float) -> UIImage {
        let height: CGFloat = 256
        let width = height * CGFloat(aspectRatio)
        let size = CGSize(width: width, height: height)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let rawShadow = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.black.setFill()
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: height * 0.06)
            path.fill()
        }
        
        guard let ciImage = CIImage(image: rawShadow),
              let blurFilter = CIFilter(name: "CIGaussianBlur") else { return rawShadow }
        
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(20.0, forKey: kCIInputRadiusKey)
        
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
    @State private var currentIndex: Int
    @State private var highResImage: UIImage?
    @State private var isLoading = true
    @State private var isInterfaceHidden = false
    
    @EnvironmentObject var fetcher: PanoramaFetcher
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("HapticState") private var isHapticEnabled = true
    
    init(currentIndex: Int) {
        _currentIndex = State(initialValue: currentIndex)
    }
    
    private var asset: PHAsset {
        fetcher.panoramas[currentIndex]
    }
    
    private var formattedDate: String {
        guard let date = asset.creationDate else { return "Unknown date" }
        return date.formatted(date: .long, time: .omitted)
    }
    
    private var formattedTime: String {
        guard let date = asset.creationDate else { return "--:--" }
        return date.formatted(date: .omitted, time: .shortened)
    }
    
    var isHorizontalLayout: Bool {
        horizontalSizeClass == .regular
        
    }
    
    var body: some View {
        GeometryReader { value in
            let isLandscape = value.size.width > value.size.height
            ZStack {
                Color.clear.ignoresSafeArea()
                
                if let image = highResImage {
                    GeometryReader { geometry in
                        SceneKitPanoramaView(image: image, size: geometry.size)
                            .id(asset.localIdentifier)
                    }
                    .ignoresSafeArea()
                    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in }
                } else if isLoading {
                    ProgressView()
                        .tint(.primary)
                } else {
                    Text("Error loading panorama.")
                        .foregroundColor(.red)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                GeometryReader { value in
                    VStack {
                        Rectangle()
                            .fill(.black.opacity(0.5))
                            .frame(height: isLandscape ? 40 : 80)
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: .black, location: 1.0)
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
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                    
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(.black.opacity(0.5))
                            .frame(height: isLandscape ? 60 : 80)
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .black, location: 1.0)
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
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            
            //MARK: - iOS 16 UI
            
            .overlay(alignment: .topLeading) {
                if #unavailable(iOS 26.0) {
                    Button(action: {
                        dismiss()
                        if isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(CircularButtonStyle())
                    .padding(.leading, 16)
                    .padding(.top, isHorizontalLayout ? 10 : 0)
                    .padding(.top, isLandscape ? 10 : 0)
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            .overlay(alignment: .top) {
                if #unavailable(iOS 26.0) {
                    Button {
                        
                    } label: {
                        VStack(alignment: .center, content: {
                            Text(formattedDate)
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text(formattedTime)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        })
                        .padding(.horizontal, 10)
                        .padding(.vertical, -0.5)
                    }
                    .allowsHitTesting(false)
                    .buttonStyle(.borderedProminent)
                    .tint(.clear)
                    .foregroundStyle(.primary)
                    .background(.ultraThinMaterial, in: Capsule())
                    .clipShape(Capsule())
                    .frame(minWidth: 80 ,maxWidth: 200, alignment: .center)
                    .shadow(color: .black.opacity(0.2), radius: 5)
                    .padding(.top, isHorizontalLayout ? 10 : 0)
                    .padding(.top, isLandscape ? 10 : 0)
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            .overlay(alignment: .topTrailing) {
                if #unavailable(iOS 26.0) {
                    Button(action: {
                        isInterfaceHidden.toggle()
                        if isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Image(systemName: isInterfaceHidden ? "eye" : "eye.slash")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.primary.opacity(isInterfaceHidden ? 0.1 : 1.0))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(CircularButtonStyle(backgroundStyle: AnyShapeStyle(.ultraThinMaterial.opacity(isInterfaceHidden ? 0.0 : 1.0))))
                    .padding(.trailing, 16)
                    .padding(.top, isHorizontalLayout ? 10 : 0)
                    .padding(.top, isLandscape ? 10 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if #unavailable(iOS 26.0) {
                    Button(action: {
                        guard currentIndex > 0 else { return }
                        currentIndex -= 1
                        if isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(CircularButtonStyle())
                    .padding(.leading, 16)
                    .padding(.bottom, isHorizontalLayout ? 10 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            .overlay(alignment: .bottom) {
                if #unavailable(iOS 26.0) {
                    Button {
                        
                    } label: {
                        Text("\(currentIndex + 1) of \(fetcher.panoramas.count)")
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
            .overlay(alignment: .bottomTrailing) {
                if #unavailable(iOS 26.0) {
                    Button(action: {
                        guard currentIndex < fetcher.panoramas.count - 1 else { return }
                        currentIndex += 1
                        if isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(CircularButtonStyle())
                    .padding(.trailing, 16)
                    .padding(.bottom, isHorizontalLayout ? 10 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            
            //MARK: - iOS 26 UI
            
            .overlay(alignment: .topLeading) {
                if #available(iOS 26.0, *) {
                    Group {
                        Button(action: {
                            dismiss()
                            if isHapticEnabled {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .regular))
                                .contentTransition(.symbolEffect(.replace))
                                .frame(width: 44, height: 44)
                        }
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive())
                        .padding(.leading)
                        .opacity(isInterfaceHidden ? 0.0 : 1.0)
                        .disabled(isInterfaceHidden)
                        .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                    }
                    .padding(.top, isLandscape ? 10 : 0)
                }
            }
            .overlay(alignment: .top) {
                if #available(iOS 26.0, *) {
                    Group {
                        VStack(alignment: .center, content: {
                            Text(formattedDate)
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Text(formattedTime)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        })
                        .frame(minWidth: 80 ,maxWidth: 200, alignment: .center)
                        .padding(.horizontal, -6)
                        .padding(.vertical, 6)
                        .glassEffect(.regular.interactive())
                        .opacity(isInterfaceHidden ? 0.0 : 1.0)
                        .disabled(isInterfaceHidden)
                        .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                    }
                    .padding(.top, isLandscape ? 10 : 0)
                }
            }
            .overlay(alignment: .topTrailing) {
                if #available(iOS 26.0, *) {
                    Group {
                        Button(action: {
                            isInterfaceHidden.toggle()
                            if isHapticEnabled {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }) {
                            Image(systemName: isInterfaceHidden ? "eye" : "eye.slash")
                                .font(.system(size: 20, weight: .regular))
                                .contentTransition(.symbolEffect(.replace))
                                .frame(width: 44, height: 44)
                        }
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive())
                        .padding(.trailing)
                        .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                    }
                    .padding(.top, isLandscape ? 10 : 0)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        guard currentIndex > 0 else { return }
                        currentIndex -= 1
                        if isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .regular))
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 44, height: 44)
                    }
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive())
                    .padding(.leading)
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            .overlay(alignment: .bottom) {
                if #available(iOS 26.0, *) {
                    Button {
                        
                    } label: {
                        Text("\(currentIndex + 1) of \(fetcher.panoramas.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(alignment: .center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 5)
                    }
                    .frame(minWidth: 60 ,maxWidth: 100, minHeight: 44, maxHeight: 44, alignment: .center)
                    .glassEffect(.regular.interactive())
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        guard currentIndex < fetcher.panoramas.count - 1 else { return }
                        currentIndex += 1
                        if isHapticEnabled {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    }) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .regular))
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 44, height: 44)
                    }
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive())
                    .padding(.trailing)
                    .opacity(isInterfaceHidden ? 0.0 : 1.0)
                    .disabled(isInterfaceHidden)
                    .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                loadHighResImage()
            }
            .onChange(of: currentIndex) { _ in
                loadHighResImage()
            }
        }
    }
    
    //MARK: - Other
    
    private func loadHighResImage() {
        highResImage = nil
        isLoading = true
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
