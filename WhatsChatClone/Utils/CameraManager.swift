import Foundation
import AVFoundation
import SwiftUI
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    func setupCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            self.configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.configureSession()
                    }
                }
            }
        default:
            print("摄像头权限被拒绝")
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        
        // 清理旧的输入（防止重复添加导致黑屏）
        session.inputs.forEach { session.removeInput($0) }
        
        // 获取前置摄像头
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("无法获取前置摄像头")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            session.commitConfiguration()
            
            // 在后台线程启动 session
            if !session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.session.startRunning()
                }
            }
        } catch {
            print("摄像头设置失败: \(error)")
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func switchCamera() {
        session.beginConfiguration()
        
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        session.removeInput(currentInput)
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .front ? .back : .front
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            // 如果切不回来，尝试还原
            session.addInput(currentInput)
            session.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            } else {
                session.addInput(currentInput)
            }
        } catch {
            session.addInput(currentInput)
        }
        
        session.commitConfiguration()
    }
}

/// 专门用于显示摄像头预览的 UIView 子类，能自动处理布局变化
class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    func setSession(_ session: AVCaptureSession) {
        videoPreviewLayer.session = session
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.setSession(session)
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // 如果 session 发生变化，可以在这里更新
        if uiView.videoPreviewLayer.session != session {
            uiView.setSession(session)
        }
    }
}
