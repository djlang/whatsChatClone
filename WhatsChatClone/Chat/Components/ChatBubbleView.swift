import SwiftUI

struct ChatBubbleView: View {
    let msg: Message
    var onDelete: () -> Void
    var onPlayVideo: (Message) -> Void
    var onPreviewImage: (Message) -> Void
    var audioPlayerManager: AudioPlayerManager
    
    var body: some View {
        HStack {
            if msg.isFromMe { Spacer() }
            
            VStack(alignment: msg.isFromMe ? .trailing : .leading, spacing: 4) {
                // 内容渲染
                messageContent
                
                // 时间显示
                Text(formatTime(msg.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: msg.isFromMe ? .trailing : .leading)
            .contextMenu {
                if msg.messageType == "text" {
                    Button {
                        UIPasteboard.general.string = msg.text
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
            
            if !msg.isFromMe { Spacer() }
        }
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch msg.messageType {
        case "image":
            if let data = msg.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .cornerRadius(10)
                    .onTapGesture { onPreviewImage(msg) }
            }
        case "location":
            LocationMessageBubble(msg: msg)
        case "video":
            VideoMessageBubble(msg: msg)
                .onTapGesture { onPlayVideo(msg) }
        case "voice":
            VoiceMessageBubble(msg: msg, isPlaying: audioPlayerManager.currentlyPlayingMessageId == msg.id){
                if let data = msg.voiceData {
                    audioPlayerManager.playVoice(data: data, messageId: msg.id)
                }
            }
        default:
            Text(msg.text ?? "")
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(msg.isFromMe ? Color.green.opacity(0.2) : Color.white)
                .cornerRadius(12)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
