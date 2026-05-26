//
//  ImagePipeline.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/26.
//

import Foundation
import ImageIO
import UIKit

enum ImagePipeline {
    
    /// 对沙盒路径下的图片进行降采样
    /// - Parameters:
    ///   - imageURL: 图片在沙盒中的本地 URL
    ///   - pointSize: 目标显示组件的尺寸（例如头像框是 65x65）
    ///   - scale: 屏幕屏幕密度（通常传入 UIScreen.main.scale，即 @2x 或 @3x）
    static func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        
        // 1. 配置高效的 ImageSource 配置，告诉系统“我只要元数据，先不要解码整个图片”
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
            return nil
        }
        
        // 2. 计算最大像素尺寸 = 视图点数 * 屏幕缩放比
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        
        // 3. 配置降采样参数
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,    // 如果没有缩略图，则强行创建
            kCGImageSourceShouldCacheImmediately: true,            // 🔴 关键：在创建时立刻进行解码，且只解码缩略图大小，后续渲染不再重复计算
            kCGImageSourceCreateThumbnailWithTransform: true,      // 自动修正照片的拍摄旋转方向
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels // 限制最大像素尺寸
        ] as CFDictionary
        
        // 4. 生成高度压缩后的 CGImage
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        // 5. 封装回 UIImage 返回
        return UIImage(cgImage: downsampledImage)
    }
}
