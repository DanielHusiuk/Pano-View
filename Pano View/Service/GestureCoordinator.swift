//
//  GestureCoordinator.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import UIKit
import SceneKit

private struct CameraPhysics {
    let maxYaw: Float
    let maxPitch: Float
    let yawSens: Float
    let pitchSens: Float
}

final class GestureCoordinator: NSObject, UIGestureRecognizerDelegate {
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
    
    private func getCameraPhysics() -> CameraPhysics {
        guard currentViewSize.height > 0,
                let camera = camera else {
            return CameraPhysics(
                maxYaw: 0,
                maxPitch: 0,
                yawSens: 0,
                pitchSens: 0
            )
        }
        
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
        
        return CameraPhysics(
            maxYaw: maxYaw,
            maxPitch: maxPitch,
            yawSens: yawSens,
            pitchSens: pitchSens
        )
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
