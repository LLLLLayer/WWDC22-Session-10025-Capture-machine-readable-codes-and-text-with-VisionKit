//
//  ViewController.swift
//  DataScannerSample
//
//  Created by Layer on 2022/6/10.
//

import UIKit
import VisionKit
import AVFoundation

class ViewController: UIViewController {
    
    // 存储我们的自定义 HighlightView 的字典，其关联的项目 ID 作为 Key 值
    var itemHighlightViews: [RecognizedItem.ID: HighlightView] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        check { [weak self] valid in
            if let self = self, valid {
                DispatchQueue.main.async {
                    self.show()
                }
            }
        }
    }
    
    // 检查设备是否有效
    private func check(completion: @escaping (Bool) -> ()) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            guard authorizationStatus == .authorized,
                  DataScannerViewController.isSupported,
                  DataScannerViewController.isAvailable else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    // 展示扫描仪
    private func show() {
        
        // 检索支持语言列表
        // print(DataScannerViewController.supportedTextRecognitionLanguages)
        
        // 指定要识别的数据类型
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = [
            .barcode(symbologies:[.qr]),
            .text(textContentType: .URL)
        ]
        
        // 创建数据扫描仪
        let dataScanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        dataScanner.delegate = self
        // 展示数据扫描仪
        present(dataScanner, animated: true) {
            try? dataScanner.startScanning()
        }
    }
    
    private func newHighlightView(forItem item: RecognizedItem) -> HighlightView {
        print(item.bounds)
        let view = HighlightView(frame: CGRect(x: item.bounds.topLeft.x,
                                               y: item.bounds.topLeft.y,
                                               width: item.bounds.topRight.x - item.bounds.topLeft.x,
                                               height: item.bounds.bottomLeft.y - item.bounds.topLeft.y))
        return view
    }
    
    private func animted(view: HighlightView, toNewBounds newBounds:RecognizedItem.Bounds) {
        view.frame = CGRect(x: newBounds.topLeft.x,
                            y: newBounds.topLeft.y,
                            width: newBounds.topRight.x - newBounds.topLeft.x,
                            height: newBounds.bottomLeft.y - newBounds.topLeft.y)
    }
    
}

extension ViewController: DataScannerViewControllerDelegate {
    
    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        switch item {
        case .text(let text):
            print("text: \(text.transcript)")
        case .barcode(let barcode):
            print("barcode: \(barcode.payloadStringValue ?? "unknown")")
        default:
            print("unexpected item")
        }
    }
    
    // 对于每个新项目，创建一个新的高亮视图并将其添加到视图层次结构中
    func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        for item in addedItems {
            let newView = newHighlightView(forItem: item)
            itemHighlightViews[item.id] = newView
            dataScanner.overlayContainerView.addSubview(newView)
        }
    }
    
    // 动画方式将高亮视图移动到新 bounds
    func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        for item in updatedItems {
            if let view = itemHighlightViews[item.id] {
                animted(view: view, toNewBounds: item.bounds)
            }
        }
    }
    
    // 高亮视图关联的项目被删除时
    func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        for item in removedItems {
            if let view = itemHighlightViews[item.id] {
                itemHighlightViews.removeValue(forKey: item.id)
                view.removeFromSuperview()
            }
        }
    }
}

