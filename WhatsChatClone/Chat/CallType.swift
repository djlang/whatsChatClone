import Foundation

/// 通话类型枚举
enum CallType: String, Identifiable {
    case audio = "语音通话"
    case video = "视频通话"
    
    // 实现 Identifiable 协议，方便 fullScreenCover 监听
    var id: String { self.rawValue }
}
