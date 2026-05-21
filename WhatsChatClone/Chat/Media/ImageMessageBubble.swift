import SwiftUI

struct ImageMessageBubble: View, MessageRenderable {
    let msg: Message
    var onPreview: (Message) -> Void
    
    init(msg: Message) {
        self.msg = msg
        self.onPreview = { _ in }
    }
    
    // 允许外部注入的 setter 方法
    func onPreview(_ action: @escaping (Message) -> Void) -> Self {
        var copy = self
        copy.onPreview = action
        return copy
    }
    
    var body: some View {
        if let data = msg.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .onTapGesture { onPreview(msg) }
        }
    }
}

