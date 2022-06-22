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
    private var session: AVCaptureSession = AVCaptureSession()
    
    // 显示来自相机设备的视频的 Core Animation layer
    private var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // UI 布局并启动
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.bounds
        
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
        // 1. 获取捕获设备对象；捕获设备提供媒体数据，单个设备可以提供一个或多个特定类型的媒体流
        guard let device = AVCaptureDevice.default(for: .video) else {
            assert(false, "Device error!")
            return
        }
        
        // 2. 从设备中捕获媒体输入，AVCaptureDeviceInput 类是用于将捕获设备连接到 Session 的具体子类
        guard let input = try? AVCaptureDeviceInput.init(device: device) else {
            assert(false, "Input error!")
            return
        }
        guard session.canAddInput(input) else {
            assert(false, "Can't add input!")
            return
        }
        session.addInput(input)
        
        // 3. VideoData 捕获输出，使用此输出来处理来自捕获视频的压缩或未压缩帧
        let output = AVCaptureVideoDataOutput.init()
        guard session.canAddOutput(output) else {
            assert(false, "Can't add output!")
        }
        session.addOutput(output)
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .default))
        
        // 4. 调整 Layer 以展示捕获会话视频
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        
        // 5. 启动捕获会话
        session.startRunning()
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // 1. 构造文本识别算法请求
        let request = VNRecognizeTextRequest(completionHandler: textDetectHandler)
        
        // 2. 请求的语言支持、质量等级、语言矫正
        request.recognitionLanguages = ["en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // 3. 创建并执行一个请求处理程序，该处理程序对样本缓冲区中包含的图像执行请求
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: .up, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            assert(false, "Request error!")
        }
    }
    
    func textDetectHandler(request: VNRequest, error: Error?) {
        // 4. 文本识别请求的结果
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        let recognizedStrings = observations.compactMap { observation in
            // 5. 返回按置信度降序排序的第 1 个候选者
            print(observation.topCandidates(1).first?.string ?? "" + "\n")
            return observation.topCandidates(1).first?.string ?? "" + "\n"
        }
        // 6. 更新 UI
        DispatchQueue.main.async {
            if let text = recognizedStrings.first {
                self.textView.text += text
            }
        }
    }
}
