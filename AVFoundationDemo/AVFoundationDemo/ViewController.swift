//
//  ViewController.swift
//  AVFoundationDemo
//
//  Created by yangjie.layer on 2022/6/9.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    // 1. 捕获会话，用来配置捕获行为、协调来自输入设备的数据流，以捕获输出的对象
    private var session: AVCaptureSession = AVCaptureSession()
    
    // 2. 显示来自相机设备的视频的 `CALayer`
    private var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 3. 调整 UI 布局，并启动数据扫描
        view.layer.addSublayer(self.previewLayer)
        previewLayer.frame = view.bounds
        start()
    }
    
    private func start() {
        // 1. 获取捕获设备对象，捕获设备提供的媒体数据，单个设备可以提供一个或多个特定类型的媒体流
        guard let device = AVCaptureDevice.default(for: .video) else {
            assert(false, "Cevice error!")
            return
        }
        
        // 2. 从设备中捕获媒体输入，AVCaptureDeviceInput 类是用于将捕获设备连接到 Session 的具体子类
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            assert(false, "Input error!")
            return
        }
        guard session.canAddInput(input) else {
            assert(false, "Can't add input!")
            return
        }
        session.addInput(input)
        
        // 3. 捕获会话生成的元数据的输出，一个拦截由其关联的捕获会话生成的元数据的对象
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        guard session.canAddOutput(output) else {
            assert(false, "Can't add output!")
            return
        }
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.global(qos: .default))
        output.metadataObjectTypes = [.qr]
        
        // 4. 调整 Layer 以展示捕获会话视频
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
        
        // 5. 启动捕获会话
        session.startRunning()
    }
    
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    // 1. 处理捕获会话生成的元数据
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !metadataObjects.isEmpty,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr else {
            return
        }
        
        // 2. 更新 UI，进行弹窗提示
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Result", message: object.stringValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
