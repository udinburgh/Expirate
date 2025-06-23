//
//  CameraPreviewModel.swift
//  DrugDetection
//
//  Created by Muhammad Hamzah Robbani on 16/06/25.
//

// MARK: - Camera Preview UIViewRepresentable

import SwiftUI
import AVFoundation
import Vision

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
