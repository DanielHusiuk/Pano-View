//
//  ShadowGeometry.swift
//  Pano View
//
//  Created by Daniel Husiuk on 30.10.2026.
//

import SwiftUI
import SceneKit

struct ShadowGeometry {
    
    static func createShadow(
        aspectRatio: Float,
        scene: SCNScene
    ) {
        let shadowGeometry = ArcGeometry.createPanoramaArc(
            aspectRatio: aspectRatio,
            radius: 10.2,
            padding: 1.8
        )
        
        let shadowMaterial = SCNMaterial()
        
        shadowMaterial.diffuse.contents = createDropShadow(
            aspectRatio: aspectRatio
        )
        
        shadowMaterial.isDoubleSided = false
        shadowMaterial.writesToDepthBuffer = false
        
        shadowGeometry.materials = [shadowMaterial]
        
        let shadowNode = SCNNode(geometry: shadowGeometry)
        shadowNode.position = SCNVector3(0, 0, 0)
        shadowNode.renderingOrder = 0
        
        scene.rootNode.addChildNode(shadowNode)
    }
    
    private static func createDropShadow(aspectRatio: Float) -> UIImage {
        let height: CGFloat = 256
        let width = height * CGFloat(aspectRatio)
        let size = CGSize(width: width, height: height)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let rawShadow = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.black.setFill()
            
            let inset: CGFloat = 18
            
            let shadowRect = CGRect(
                x: inset,
                y: inset,
                width: size.width - inset * 2,
                height: size.height - inset * 2
            )
            
            let path = UIBezierPath(
                roundedRect: shadowRect,
                cornerRadius: height * 0.06
            )
            
            path.fill()
        }
        
        guard let ciImage = CIImage(image: rawShadow),
              let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            return rawShadow
        }
        
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(20.0, forKey: kCIInputRadiusKey)
        
        let context = CIContext()
        
        if let output = blurFilter.outputImage,
           let cgImage = context.createCGImage(
            output,
            from: ciImage.extent
           ) {
            return UIImage(cgImage: cgImage)
        }
        
        return rawShadow
    }
}
