//
//  ArcGeometry.swift
//  Pano View
//
//  Created by Daniel Husiuk on 30.10.2026.
//

import SwiftUI
import SceneKit

struct ArcGeometry {
    
    static func createArcGeometry(
        image: UIImage,
        aspectRatio: Float,
        scene: SCNScene
    ) {
        let arcGeometry = createPanoramaArc(
            aspectRatio: aspectRatio,
            radius: 10.0
        )
        
        let material = SCNMaterial()
        material.diffuse.contents = image.cgImage
        material.isDoubleSided = false
        material.diffuse.mipFilter = .linear
        material.transparent.contents = createCornerMask(
            aspectRatio: aspectRatio
        )
        
        arcGeometry.materials = [material]
        
        let arcNode = SCNNode(geometry: arcGeometry)
        arcNode.position = SCNVector3(0, 0, 0)
        arcNode.renderingOrder = 1
        
        scene.rootNode.addChildNode(arcNode)
    }
    
    static func calculateAngle(aspectRatio: Float) -> Float {
        let radius: Float = 10.0
        let verticalFOVRadians: Float = 65.0 * .pi / 180.0
        
        let height = 2.0 * radius * tan(verticalFOVRadians / 2.0)
        let arcLength = height * aspectRatio
        
        return min(arcLength / radius, Float.pi * 2.0)
    }
    
    static func createPanoramaArc(
        aspectRatio: Float,
        radius: Float,
        padding: Float = 0.0,
        expandScale: Float = 1.0
    ) -> SCNGeometry {
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
        
        for value in 0...segments {
            let currentAngle = startAngle + Float(value) * angleStep
            
            let xValue = radius * sin(currentAngle)
            let zValue = -radius * cos(currentAngle)
            
            vertices.append(SCNVector3(xValue, height / 2.0, zValue))
            uvs.append(CGPoint(
                x: CGFloat(value) / CGFloat(segments),
                y: 0.0
            ))
            
            vertices.append(SCNVector3(xValue, -height / 2.0, zValue))
            uvs.append(CGPoint(
                x: CGFloat(value) / CGFloat(segments),
                y: 1.0
            ))
        }
        
        for value in 0..<segments {
            let top1 = UInt32(value * 2)
            let bot1 = UInt32(value * 2 + 1)
            let top2 = UInt32((value + 1) * 2)
            let bot2 = UInt32((value + 1) * 2 + 1)
            
            indices.append(contentsOf: [
                top1, bot1, top2,
                bot1, bot2, top2
            ])
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let uvSource = SCNGeometrySource(textureCoordinates: uvs)
        
        let element = SCNGeometryElement(
            indices: indices,
            primitiveType: .triangles
        )
        
        return SCNGeometry(
            sources: [vertexSource, uvSource],
            elements: [element]
        )
    }
    
    private static func createCornerMask(aspectRatio: Float) -> UIImage {
        let height: CGFloat = 512
        let width = height * CGFloat(aspectRatio)
        let size = CGSize(width: width, height: height)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.white.setFill()
            
            let path = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: height * 0.04
            )
            
            path.fill()
        }
    }
}
