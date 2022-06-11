//
//  ViewController.swift
//  AVFoundationAndVisionDemo
//
//  Created by yangjie.layer on 2022/6/9.
//

import UIKit
import Vision
import AVFoundation

class ViewController: UIViewController {
    
    // 捕获会话，用来配置捕获行为，并协调来自输入设备的数据流，以捕获输出的对象
    lazy var session: AVCaptureSession = {
        return AVCaptureSession.init()
    }()
    
    // 显示来自相机设备的视频的 Core Animation layer
    lazy var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer = {
        return AVCaptureVideoPreviewLayer.init()
    }()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // UI 布局并启动
        view.layer.addSublayer(captureVideoPreviewLayer)
        captureVideoPreviewLayer.frame = view.bounds
        
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16.0),
            textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16.0),
            textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 56.0),
            textView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        start()
    }
    
    func start() {
        // 获取捕获设备对象；捕获设备提供媒体数据，单个设备可以提供一个或多个特定类型的媒体流
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            assert(false, "CaptureDevice error!")
            return
        }
        
        // 从设备中捕获媒体输入；AVCaptureDeviceInput 类是用于将捕获设备连接到 Session 的具体子类
        guard let captureDeviceInput = try? AVCaptureDeviceInput.init(device: captureDevice) else {
            assert(false, "CaptureDeviceInput error!")
            return
        }
        session.addInput(captureDeviceInput)
        
        // VideoData 捕获输出，使用此输出来处理来自捕获视频的压缩或未压缩帧
        let captureVideoDataOutput = AVCaptureVideoDataOutput.init()
        session.addOutput(captureVideoDataOutput)
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))
        
        // 调整 Core Animation layer 以展示捕获会话视频
        captureVideoPreviewLayer.session = session
        captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        
        // 启动捕获会话
        session.startRunning()
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // 创建一个请求处理程序，该处理程序对样本缓冲区中包含的图像执行请求
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .down)
        
        // 文本识别算法
        let request = VNRecognizeTextRequest(completionHandler: textDetectHandler)
        do {
            try requestHandler.perform([request])
        } catch {
            assert(false, "Request error!")
        }
    }
    
    func textDetectHandler(request: VNRequest, error: Error?) {
        // 文本识别请求的结果
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        let recognizedStrings = observations.compactMap { observation in
            // 返回按置信度降序排序的第 1 个候选者
            return observation.topCandidates(1).first?.string
        }
        // 更新 UI
        DispatchQueue.main.async {
            if let text = recognizedStrings.first {
                self.textView.text += text
            }
        }
    }
}
