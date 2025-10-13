//
//  QRCodeScannerView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

/*
// COMMENTED OUT FOR MAC SIMULATION
// QR Code Scanner functionality disabled to allow app to run on Mac

import SwiftUI
import AVFoundation

/// A SwiftUI view that provides QR code scanning functionality using the device's camera.
/// 
/// This view wraps `AVCaptureSession` to provide real-time QR code detection and scanning.
/// It follows Apple's design guidelines for camera-based scanning interfaces.
///
/// - Note: Requires camera permission to function properly.
/// - Important: This view should only be used on physical devices as the simulator doesn't support camera functionality.
@available(iOS 14.0, *)
struct QRCodeScannerView: UIViewRepresentable {
    
    // MARK: - Properties
    
    /// The scanned QR code content as a binding.
    @Binding var scannedCode: String
    
    /// Whether the scanner is currently active as a binding.
    @Binding var isScanning: Bool
    
    /// Optional callback for handling scan errors.
    let onError: ((QRScannerError) -> Void)?
    
    /// The quality preset for the capture session.
    let sessionPreset: AVCaptureSession.Preset
    
    // MARK: - Initialization
    
    /// Creates a new QR code scanner view.
    /// - Parameters:
    ///   - scannedCode: Binding to the scanned code string.
    ///   - isScanning: Binding to control scanning state.
    ///   - onError: Optional error handler.
    ///   - sessionPreset: The capture session quality preset.
    init(
        scannedCode: Binding<String>,
        isScanning: Binding<Bool>,
        onError: ((QRScannerError) -> Void)? = nil,
        sessionPreset: AVCaptureSession.Preset = .high
    ) {
        self._scannedCode = scannedCode
        self._isScanning = isScanning
        self.onError = onError
        self.sessionPreset = sessionPreset
    }
    
    // MARK: - UIViewRepresentable Implementation
    
    func makeUIView(context: Context) -> UIView {
        let view = QRScannerView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let scannerView = uiView as? QRScannerView else { return }
        
        if isScanning {
            scannerView.startScanning()
        } else {
            scannerView.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator

@available(iOS 14.0, *)
extension QRCodeScannerView {
    
    /// Coordinator class that handles the communication between the scanner and SwiftUI.
    class Coordinator: NSObject, QRScannerDelegate {
        
        // MARK: - Properties
        
        let parent: QRCodeScannerView
        
        // MARK: - Initialization
        
        init(_ parent: QRCodeScannerView) {
            self.parent = parent
        }
        
        // MARK: - QRScannerDelegate Implementation
        
        func qrScanner(_ scanner: QRScannerView, didDetectCode code: String) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.scannedCode = code
                self.parent.isScanning = false
            }
        }
        
        func qrScanner(_ scanner: QRScannerView, didFailWithError error: QRScannerError) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.onError?(error)
            }
        }
    }
}

// MARK: - QR Scanner Error

/// Errors that can occur during QR code scanning.
enum QRScannerError: LocalizedError {
    case cameraNotAvailable
    case cameraPermissionDenied
    case sessionConfigurationFailed
    case metadataOutputNotSupported
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available on this device."
        case .cameraPermissionDenied:
            return "Camera permission is required to scan QR codes."
        case .sessionConfigurationFailed:
            return "Failed to configure camera session."
        case .metadataOutputNotSupported:
            return "QR code scanning is not supported on this device."
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .cameraNotAvailable:
            return "Please use a device with a camera."
        case .cameraPermissionDenied:
            return "Please grant camera permission in Settings."
        case .sessionConfigurationFailed:
            return "Please restart the app and try again."
        case .metadataOutputNotSupported:
            return "Please use a device that supports QR code scanning."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - QR Scanner Delegate Protocol

/// Protocol for handling QR scanner events.
protocol QRScannerDelegate: AnyObject {
    func qrScanner(_ scanner: QRScannerView, didDetectCode code: String)
    func qrScanner(_ scanner: QRScannerView, didFailWithError error: QRScannerError)
}

// MARK: - QR Scanner View

/// A UIView that handles the camera session and QR code detection.
@available(iOS 14.0, *)
class QRScannerView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: QRScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionPreset: AVCaptureSession.Preset
    
    // MARK: - Initialization
    
    init(sessionPreset: AVCaptureSession.Preset = .high) {
        self.sessionPreset = sessionPreset
        super.init(frame: .zero)
        setupScanner()
    }
    
    required init?(coder: NSCoder) {
        self.sessionPreset = .high
        super.init(coder: coder)
        setupScanner()
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    // MARK: - Public Methods
    
    /// Starts the scanning session.
    func startScanning() {
        guard let captureSession = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }
    
    /// Stops the scanning session.
    func stopScanning() {
        guard let captureSession = captureSession else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupScanner() {
        setupCaptureSession()
        setupPreviewLayer()
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = sessionPreset
        
        // Configure video input
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.qrScanner(self, didFailWithError: .cameraNotAvailable)
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                delegate?.qrScanner(self, didFailWithError: .sessionConfigurationFailed)
                return
            }
        } catch {
            delegate?.qrScanner(self, didFailWithError: .unknown(error))
            return
        }
        
        // Configure metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.qrScanner(self, didFailWithError: .metadataOutputNotSupported)
            return
        }
        
        self.captureSession = session
    }
    
    private func setupPreviewLayer() {
        guard let captureSession = captureSession else { return }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = bounds
        
        layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

@available(iOS 14.0, *)
extension QRScannerView: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        delegate?.qrScanner(self, didDetectCode: stringValue)
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct QRCodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScannerView(
            scannedCode: .constant(""),
            isScanning: .constant(true)
        )
        .previewDisplayName("QR Code Scanner")
    }
}
*/

// MARK: - Mock QR Code Scanner for Mac Simulation

import SwiftUI

/// Mock QR Code Scanner for Mac simulation
@available(iOS 14.0, *)
struct QRCodeScannerView: UIViewRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanning: Bool
    let onError: ((QRScannerError) -> Void)?
    let sessionPreset: String // Changed from AVCaptureSession.Preset to String
    
    init(
        scannedCode: Binding<String>,
        isScanning: Binding<Bool>,
        onError: ((QRScannerError) -> Void)? = nil,
        sessionPreset: String = "high" // Changed default value
    ) {
        self._scannedCode = scannedCode
        self._isScanning = isScanning
        self.onError = onError
        self.sessionPreset = sessionPreset
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray5
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Mock implementation - no actual scanning
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: QRCodeScannerView
        
        init(_ parent: QRCodeScannerView) {
            self.parent = parent
        }
    }
}

/// Mock QR Scanner Error for Mac simulation
enum QRScannerError: LocalizedError {
    case cameraNotAvailable
    case cameraPermissionDenied
    case sessionConfigurationFailed
    case metadataOutputNotSupported
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available on this device."
        case .cameraPermissionDenied:
            return "Camera permission is required to scan QR codes."
        case .sessionConfigurationFailed:
            return "Failed to configure camera session."
        case .metadataOutputNotSupported:
            return "QR code scanning is not supported on this device."
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .cameraNotAvailable:
            return "Please use a device with a camera."
        case .cameraPermissionDenied:
            return "Please grant camera permission in Settings."
        case .sessionConfigurationFailed:
            return "Please restart the app and try again."
        case .metadataOutputNotSupported:
            return "Please use a device that supports QR code scanning."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}
