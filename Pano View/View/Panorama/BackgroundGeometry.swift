//
//  BackgroundGeometry.swift
//  Pano View
//
//  Created by Daniel Husiuk on 30.10.2026.
//

import SwiftUI
import SceneKit

struct BackgroundGeometry {
    
    static func createBackground(
        image: UIImage,
        aspectRatio: Float,
        scene: SCNScene
    ) {
        let backgroundGeometry = ArcGeometry.createPanoramaArc(
            aspectRatio: aspectRatio,
            radius: 15.0,
            expandScale: 4.0
        )
        
        let tinySize = CGSize(
            width: 300,
            height: 300 / CGFloat(aspectRatio)
        )
        
        let renderer = UIGraphicsImageRenderer(size: tinySize)
        
        let tinyImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: tinySize))
        }
        
        var blurryImage = tinyImage
        
        if let ciImage = CIImage(image: tinyImage),
           let blurFilter = CIFilter(name: "CIGaussianBlur") {
            
            blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
            blurFilter.setValue(15.0, forKey: kCIInputRadiusKey)
            
            let context = CIContext()
            
            if let output = blurFilter.outputImage,
               let cgImage = context.createCGImage(
                output,
                from: ciImage.extent
               ) {
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
    }
}
