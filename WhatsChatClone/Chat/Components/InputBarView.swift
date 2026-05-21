import SwiftUI
import PhotosUI

struct InputBarView: View {
    
    @Binding var inputText: String
    @Binding var isVoiceMode: Bool
    @FocusState.Binding var isInputFocused: Bool
    var onToggleAttachment: () -> Void
    var onSendMessage: () -> Void
    var onToggleVoiceMode: () -> Void
    var onRecordComplete: (Data, Double) -> Void
    
    // 关键新增：把控制全屏蒙层的两个状态传进来，供内部的 VoiceRecordButton 使用
    @Binding var isRecordingVoice: Bool
    @Binding var isRecordingCancelled: Bool
    
    @Binding var voiceAudioLevel: Float // 传递音量大小 (0.1 ~ 1.0)
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleAttachment) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            if isVoiceMode {
                VoiceRecordButton(isRecording: $isRecordingVoice, isCancelled: $isRecordingCancelled, audioLevel: $voiceAudioLevel) { data, duration in
                    onRecordComplete(data, duration)
                }
                    .frame(height: 40)
                    .padding(.horizontal, 4)
            } else {
                TextField("输入消息...", text: $inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            if !inputText.isEmpty && !isVoiceMode {
                Button(action: onSendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            } else {
                Button(action: onToggleVoiceMode) {
                    Image(systemName: isVoiceMode ? "keyboard" : "mic")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
