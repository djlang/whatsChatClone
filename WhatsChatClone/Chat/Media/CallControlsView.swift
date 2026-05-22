import SwiftUI

struct CallControlsView: View {
    let callType: CallType
    
    @Binding var isMuted: Bool
    @Binding var isSpeakerOn: Bool
    @Binding var isVideoOff: Bool
    
    var onHangup: () -> Void
    var onFlipCamera: () -> Void
    
    var body: some View {
        if callType == .video {
            videoControls
        } else {
            audioControls
        }
    }
    
    // MARK: - 视频通话布局 (两行网格)
    private var videoControls: some View {
        VStack(spacing: 30) {
            // 第一行：麦克风、扩音、摄像头
            HStack(spacing: 30) {
                controlButton(icon: isMuted ? "mic.slash.fill" : "mic.fill", label: isMuted ? "麦克风已关闭" : "麦克风已开启", isActive: isMuted) {
                    isMuted.toggle()
                }
                
                controlButton(icon: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.1.fill", label: isSpeakerOn ? "扩音已开启" : "扩音已关闭", isActive: isSpeakerOn) {
                    isSpeakerOn.toggle()
                }
                
                controlButton(icon: isVideoOff ? "video.slash.fill" : "video.fill", label: "摄像头", isActive: isVideoOff) {
                    isVideoOff.toggle()
                }
            }
            
            // 第二行：背景蒙版(预留)、挂断、翻转
            HStack(spacing: 30) {
                controlButton(icon: "sparkles", label: "效果", isActive: false) {
                    // 未来增加蒙版/特效逻辑
                }
                
                hangupButton()
                
                controlButton(icon: "camera.rotate.fill", label: "翻转", isActive: false) {
                    onFlipCamera()
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 语音通话布局 (单行)
    private var audioControls: some View {
        HStack(spacing: 40) {
            controlButton(icon: isMuted ? "mic.slash.fill" : "mic.fill", label: isMuted ? "麦克风已关闭" : "麦克风已开启", isActive: isMuted) {
                isMuted.toggle()
            }
            
            hangupButton()
            
            controlButton(icon: isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.1.fill", label: isSpeakerOn ? "扩音已开启" : "扩音已关闭", isActive: isSpeakerOn) {
                isSpeakerOn.toggle()
            }
        }
    }
    
    // MARK: - 辅助组件
    @ViewBuilder
    private func controlButton(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(isActive ? Color.white : Color.white.opacity(0.2))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(isActive ? .black : .white)
                    )
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    @ViewBuilder
    private func hangupButton() -> some View {
        Button(action: onHangup) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "phone.down.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    )
                Text("挂断")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}
