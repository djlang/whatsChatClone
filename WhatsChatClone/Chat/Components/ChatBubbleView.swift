
import SwiftUI

struct ChatBubbleView: View {
    let msg: Message
    let chatName: String // 💡 注入会话名称，用以完美判定单聊/群聊
    var onDelete: () -> Void
    var onPlayVideo: (Message) -> Void
    var onPreviewImage: (Message) -> Void
    var audioPlayerManager: AudioPlayerManager
    
    // 💡 状态判定：名字包含“群”、“交流”、“沙龙”等关键字即为群聊
    private var isGroupChat: Bool {
        chatName.contains("群") || chatName.contains("交流") || chatName.contains("沙龙")
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            
            // ==========================================
            // 1. 🧔 对方发送的消息：左侧头像区
            // ==========================================
            if !msg.isFromMe {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 38, height: 38)
                    .overlay(
                        // 群聊优先用群友头像，单聊用默认头像
                        Image(systemName: msg.senderAvatar ?? "person.crop.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    )
                    .padding(.leading, 8)
            } else {
                // 我发的，左侧留出 Spacer 把气泡推到最右
                Spacer()
            }
            
            // ==========================================
            // 2. 💬 核心：多媒体内容渲染 + 昵称/时间层
            // ==========================================
            VStack(alignment: msg.isFromMe ? .trailing : .leading, spacing: 4) {
                
                // 🔴 像素级细节：只有【非我发送】且【是群聊】时，气泡上方才亮起群友昵称
                if !msg.isFromMe && isGroupChat {
                    Text(msg.senderName ?? chatName)
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                        .padding(.leading, 4)
                }
                
                // 📦 完好保留你所有的多媒体渲染逻辑
                messageContent
                    .contextMenu {
                        if msg.messageType == "text" {
                            Button {
                                UIPasteboard.general.string = msg.text ?? ""
                            } label: {
                                Label("复制", systemImage: "doc.on.doc")
                            }
                        }
                        if msg.messageType == "image" || msg.messageType == "video" {
                            Button {
                                MediaService.shared.saveToGallery(msg: msg)
                            } label: {
                                Label("保存到相册", systemImage: "square.and.arrow.down")
                            }
                        }
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                
                // 时间显示
                Text(formatTime(msg.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            // 💡 保证在保留头像的同时，多媒体气泡的最大宽度依然维持在黄金比例
            .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: msg.isFromMe ? .trailing : .leading)
            
            // ==========================================
            // 3.  我发送的消息：右侧头像区
            // ==========================================
            if msg.isFromMe {
                Circle()
                    .fill(Color(red: 0.0, green: 0.53, blue: 0.43)) // 微信经典绿作为我方头像底板
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                    )
                    .padding(.trailing, 8)
            } else {
                // 对方发的，右侧留出 Spacer 把气泡挡在左侧
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    // ==========================================
    // 🎨 完整承袭并调优的 messageContent 模块
    // ==========================================
    @ViewBuilder
    private var messageContent: some View {
        switch msg.messageType {
        case "image":
            ImageMessageBubble(msg: msg).onPreview(onPreviewImage)
        case "location":
            LocationMessageBubble(msg: msg)
        case "video":
            VideoMessageBubble(msg: msg)
                .onTapGesture { onPlayVideo(msg) }
        case "voice":
            VoiceMessageBubble(msg: msg, isPlaying: audioPlayerManager.currentlyPlayingMessageId == msg.id) {
                if let data = msg.voiceData {
                    audioPlayerManager.playVoice(data: data, messageId: msg.id)
                }
            }
        default:
            // 文本气泡：把原来的圆角升级成地道的非对称圆角
            Text(msg.text ?? "")
                .font(.system(size: 16))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(msg.isFromMe ? Color.waMyBubble : Color.waOtherBubble)
                .foregroundColor(msg.isFromMe ? .white : .primary)
                .clipShape(BubbleCornerRadiusShape(isFromMe: msg.isFromMe))
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 🎨 微信高仿气泡不规则圆角微修
struct BubbleCornerRadiusShape: Shape {
    let isFromMe: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft, .topRight,
                isFromMe ? .bottomLeft : .bottomRight // 巧妙留出气泡的小尾巴角
            ],
            cornerRadii: CGSize(width: 14, height: 14)
        )
        return Path(path.cgPath)
    }
}
