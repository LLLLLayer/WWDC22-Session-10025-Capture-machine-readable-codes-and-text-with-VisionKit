//
//  ViewController.swift
//  AVFoundationDemo
//
//  Created by yangjie.layer on 2022/6/9.
//

import UIKit
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // UI 布局并启动
        view.layer.addSublayer(self.captureVideoPreviewLayer)
        captureVideoPreviewLayer.frame = view.bounds
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
        
        // 捕获会话生成的元数据的输出；一个拦截由其关联的捕获会话生成的元数据的对象
        let captureDeviceOutput = AVCaptureMetadataOutput.init()
        session.addOutput(captureDeviceOutput)
        captureDeviceOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.global(qos: .default))
        print(captureDeviceOutput.availableMetadataObjectTypes)
        captureDeviceOutput.metadataObjectTypes = [.qr]
        
        // 调整 Core Animation layer 以展示捕获会话视频
        captureVideoPreviewLayer.session = session
        captureVideoPreviewLayer.videoGravity = .resizeAspectFill
        
        // 启动捕获会话
        session.startRunning()
    }
    
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    // 处理捕获会话生成的元数据
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !metadataObjects.isEmpty,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr else {
            return
        }
        DispatchQueue.main.async {
            let alert = UIAlertController.init(title: "Result", message: object.stringValue, preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
}
