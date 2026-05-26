//
//  ImageCacheManager.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/26.
//

import UIKit

final class ImageCacheManager {
    static let shared = ImageCacheManager()
    private init() {
        // 设置内存缓存配额，比如最多存 50MB 的图片对象
        memoryCache.totalCostLimit = 50 * 1024 * 1024
    }
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    // 获取沙盒缓存根目录
    private var diskCacheURL: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("WhatsChatImageCache")
    }
    
    /// 读取图片（先内存，后磁盘，都没有则返回 nil）
    func image(forKey key: String, targetSize: CGSize) -> UIImage? {
        let nsKey = key as NSString
        
        // 1. 探查内存缓存
        if let cachedImage = memoryCache.object(forKey: nsKey) {
            return cachedImage
        }
        
        // 2. 探查磁盘文件
        let fileURL = diskCacheURL.appendingPathComponent(key)
        if fileManager.fileExists(atPath: fileURL.path) {
            // 🔴 磁盘有原图，立刻调用第一战的“降采样黑魔法”转换为指定大小的缩略图
            if let downsampledImage = ImagePipeline.downsample(imageAt: fileURL, to: targetSize) {
                // 顺手回填到内存缓存，下次直接秒开
                memoryCache.setObject(downsampledImage, forKey: nsKey)
                return downsampledImage
            }
        }
        
        return nil
    }
    
    /// 存储原生原始图片数据到磁盘
    func saveImage(data: Data, forKey key: String) {
        // 确保缓存夹子存在
        if !fileManager.fileExists(atPath: diskCacheURL.path) {
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
        
        let fileURL = diskCacheURL.appendingPathComponent(key)
        try? data.write(to: fileURL)
    }
}

/////体积计算和一键清理方法：

extension ImageCacheManager {
    
    /// 动态计算整个图片缓存文件夹的实际大小（单位：MB）
    func computeCacheSize() -> Double {
        guard let resourceValues = try? diskCacheURL.resourceValues(forKeys: [.isDirectoryKey]),
              resourceValues.isDirectory == true else { return 0.0 }
        
        var totalSize: Int64 = 0
        let properties: [URLResourceKey] = [.fileSizeKey]
        
        let enumerator = fileManager.enumerator(at: diskCacheURL, includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if let vals = try? fileURL.resourceValues(forKeys: [.fileSizeKey]), let size = vals.fileSize {
                totalSize += Int64(size)
            }
        }
        
        // 转换为 MB
        return Double(totalSize) / (1024.0 * 1024.0)
    }
    
    /// 格式化清理磁盘与内存全部缓存
    func clearAllCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: diskCacheURL)
        print("🧹 磁盘和内存图片缓存已彻底荡平！")
    }
}
