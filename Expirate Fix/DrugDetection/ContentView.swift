//
//  ContentView.swift
//  DrugDetection
//
//  Created by Muhammad Hamzah Robbani on 04/06/25.
//

//
//  ContentView.swift
//  CobaOCR
//
//  Created by Muhammad Hamzah Robbani on 04/06/25.
//

import SwiftUI
import AVFoundation
import Vision

extension Date{
    
    func toString(format: String = "d MMMM yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format // or "MMMM d, yyyy", etc.
        return formatter.string(from: self)
    }
}

struct ContentView: View {
    //    @StateObject var cameraManager = UnifiedCameraManager()
    private func checkTimeToShowResult(){
        if detectedExpiredDate != nil && detectedDrugName != nil {
            showDrugDetectionResult = true
            cameraView_Model.modeOCR = .drug_name
        }
    }
    
    @StateObject private var cameraView_Model = CameraView_Model()
    @State var detectedDrugName: String? = nil{didSet {checkTimeToShowResult()}}
    @State var detectedExpiredDate: Date? = nil{didSet {checkTimeToShowResult()}}
    @State var accessibilityStatus = "Memindai " // Simple status for VoiceOver users
    @State var showDrugDetectionResult = false
    private var detectDrugName: Bool = false
    @State var showHelpView = false
    @State private var modeOCR : ModeOCR? = ModeOCR.drug_name
    //ini dari rifqi belum teruji
    private func userConfirmedDrugName(_ confirmed: Bool) {
        //        if confirmed {
        //            // User confirmed the drug name, move to expiration date phase
        //            ocrPhase = .expirationDate
        //            detectedDrugName = detectedDrugName // Keep the detected name
        //
        //            DispatchQueue.main.async {
        //                self.statusMessage = "📅 SCANNING EXPIRATION"
        //                self.descriptionMessage = "Drug confirmed: \(self.detectedDrugName ?? "")\nNow scanning for expiration date"
        //                self.accessibilityStatus = "Nama obat dikonfirmasi. Sekarang memindai tanggal kadaluarsa"
        //                self.ocrStatus = "Looking for expiration date..."
        //                self.positioningGuidance = "Point camera at expiration date area"
        //            }
        //
        //            // Resume OCR processing for expiration date detection
        //            resumeCameraAndOCR()
        //
        //            // Provide guidance for expiration date scanning (VoiceOver-aware)
        //            if !isVoiceOverRunning {
        //                speakGuidance("Nama obat dikonfirmasi. Sekarang arahkan kamera ke area tanggal kadaluarsa", priority: true)
        //            }
        //
        //        } else {
        //            // User rejected the drug name, continue scanning for drug names
        //            detectedDrugName = nil
        //        }
    }
    
    //    private func startDetectExpiredDate(){
    //        cameraView_Model.OCR(status:)
    //    }
    
    init(){
        cameraView_Model.modeOCR = .drug_name
        cameraView_Model.OCR(true) // Aktifkan OCR
        
        
        
        if let modeOCR = modeOCR{
            switch(modeOCR){
            case ModeOCR.expired_date:
                cameraView_Model.OCR(true)
                if let detectedExpiredDate = cameraView_Model.detectedExpiredDate{
                    print("masukcontentview \(detectedExpiredDate)")
                    self.detectedExpiredDate = detectedExpiredDate
                }
                break
            case ModeOCR.drug_name:
                if let detectedDrugName = cameraView_Model.detectedDrugName{
                    print("masukcontentview \(detectedDrugName)")
                    self.detectedDrugName = detectedDrugName
                }
                cameraView_Model.OCR(false)
                break
            }
        }
        
        
    }
    
    private func speakDrugNameIfNeeded(_ drugName: String) {
        //        guard lastSpokenDrugName != drugName else { return }
        //        lastSpokenDrugName = drugName
        //        stopSpeaking()
        //        let utterance = AVSpeechUtterance(string: "Obat terdeteksi: \(drugName)")
        //        utterance.voice = AVSpeechSynthesisVoice(language: "id-ID") ?? AVSpeechSynthesisVoice(language: "en-US")
        //        utterance.rate = 0.5
        //        utterance.volume = 1.0
        //        speechSynthesizer.speak(utterance)
    }
    
    
    
    var body: some View {
        NavigationStack{
            ZStack(alignment: .bottom) {
                CameraPreview(session: cameraView_Model.session)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    HStack {
                        // Flash button
                        
                        Spacer()
                        
                        Text("Memindai").bold().padding(.leading, 30)
                        
                        Spacer()
                        
                        // Help button
                        Button(action: {
                            // Pesan yang akan diucapkan
                            let helpMessage = "Arahkan kamera ke obat untuk memindai"
                            
                            // Trigger VoiceOver announcement
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                UIAccessibility.post(notification: .announcement, argument: helpMessage)
                            }
                            self.showHelpView = true
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.title3)
                                .frame(width: 30, height: 30)
                                .background(Color.black)
                                .clipShape(Circle())
                        }
                        // Pengaturan aksesibilitas yang tepat:
                        .accessibilityElement(children: .combine)  // Gabungkan elemen anak
                        .accessibilityLabel("Bantuan pemindaian") // Label sederhana
                        .accessibilityHint("Ketuk untuk petunjuk pemindaian") // Hint jelas
                        .accessibilityAddTraits(.isButton) // Pastikan dikenali sebagai tombol
                    }
                    .padding(.horizontal, 32)
                    
                    
                    if let detectedDrugName = detectedDrugName {
                        HStack{
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Nama Obat Terdeteksi: '\(detectedDrugName)'")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(20)
                            .padding(.leading, 10)
                            Spacer()
                        }
                    }
                    
                    if let detectedExpiredDate = detectedExpiredDate {
                        HStack{
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Tanggal Kedaluwarsa Terdeteksi: '\(detectedExpiredDate)'")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(20)
                            .padding(.leading, 10)
                            Spacer()
                        }
                    }
                    
                    Spacer()
                }
                
                //ini hanya untuk debug
                //                Text(cameraView_Model.detectedExpiredDate?.toString() ?? cameraView_Model.recognizedPossibleExpiredDate ??  "Searching..")
                //                    .padding()
                //                    .background(Color.black.opacity(0.5))
                //                    .foregroundColor(cameraView_Model.detectedExpiredDate != nil ? .green : .white)
                //                    .frame(maxWidth: .infinity, alignment: .leading)
                //                    .font(.headline)
                
                // Clean accessibility status for VoiceOver users
                VStack {
                    Spacer()
                    
                    // Primary accessibility status
                    Text(accessibilityStatus)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .accessibilityLabel(accessibilityStatus)
                    
                    Spacer().frame(height: 40)
                    
                    // Tap to focus hint (VoiceOver friendly)
                    //                Text(cameraView_Model.modeOCR == .drug_name ? "Ketuk tengah layar untuk membantu fokus kamera pada nama obat" : "Ketuk tengah layar untuk membantu fokus kamera pada tanggal kadaluarsa")
                    //                    .foregroundColor(.white.opacity(0.8))
                    //                    .font(.body)
                    //                    .multilineTextAlignment(.center)
                    //                    .shadow(color: .black, radius: 1)
                    //                    .accessibilityLabel(cameraView_Model.modeOCR == .drug_name ? "Ketuk tengah layar untuk membantu kamera fokus pada nama obat" : "Ketuk tengah layar untuk membantu kamera fokus pada tanggal kadaluarsa")
                    //                    .accessibilityHint("Ketuk dua kali untuk mengaktifkan fokus kamera")
                    //
                    //                Spacer().frame(height: 30)
                }
                
                //            CameraBottomOverlay(
                //                cameraManager: cameraView_Model,
                //                detectedDrugName: $detectedDrugName,
                //                onDrugNameConfirm: { userConfirmedDrugName(true) },
                //                onDrugNameAppear: {
                //                    if let drugName = detectedDrugName {
                //                        speakDrugNameIfNeeded(drugName)
                //                    }
                //                },
                //                onDrugNameDisappear: {}//stopSpeaking() }
                //            )
                
                
            }
            .onAppear {cameraView_Model.startSession()}
            .onDisappear {cameraView_Model.stopSession()}
            .navigationDestination(isPresented: $showDrugDetectionResult) {ResultView(detectedDate: detectedExpiredDate, detectedDrugName: detectedDrugName)}
            .navigationDestination(isPresented: $showHelpView) {Help_View()}
            .onChange(of: showDrugDetectionResult){
                if !showDrugDetectionResult{
                    self.detectedExpiredDate = nil
                    self.detectedDrugName = nil
                }
            }
            .onChange(of: cameraView_Model.detectedDrugName) { drugName in
                if !showDrugDetectionResult{
                    if let detectedDrugName = drugName{
                        self.detectedDrugName = detectedDrugName
                        cameraView_Model.modeOCR = .expired_date
                    }
                }
            }
            .onChange(of: cameraView_Model.detectedExpiredDate) { detectedExpiredDate in
                if !showDrugDetectionResult{
                    if let detectedExpiredDate = detectedExpiredDate{
                        self.detectedExpiredDate = detectedExpiredDate
                        //                    self.detectedDrugName = cameraView_Model.detectedDrugName //showDrugDetectionResult=true
                    }
                }
                
            }
            
            
        }
        
    }
}

//struct CameraBottomOverlay: View {
//    @ObservedObject var cameraManager: CameraView_Model
//    @Binding var detectedDrugName: String?
//    var onDrugNameConfirm: (() -> Void)? = nil
//    var onDrugNameAppear: (() -> Void)? = nil
//    var onDrugNameDisappear: (() -> Void)? = nil
//
//    var body: some View {
//        VStack {
//            Spacer()
//            if cameraManager.modeOCR == .drug_name {
//                if let drugName = detectedDrugName {
//                    // Drug name detected, show confirmation overlay
//                    VStack(alignment: .center, spacing: 8) {
//                        Text(drugName)
//                            .font(.system(size: 38, weight: .bold))
//                            .foregroundColor(.white)
//                            .multilineTextAlignment(.center)
//                            .shadow(radius: 4)
//                            .padding(.horizontal, 16)
//                        Text("Ketuk layar dua kali untuk konfirmasi")
//                            .font(.title3)
//                            .foregroundColor(.white)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal, 16)
//                            .padding(.bottom, 8)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .background(Color.black.opacity(0.01)) // for tap gesture
//                    .onAppear { onDrugNameAppear?() }
//                    .onDisappear { onDrugNameDisappear?() }
//                    .highPriorityGesture(
//                        TapGesture(count: 2)
//                            .onEnded { onDrugNameConfirm?() }
//                    )
//                } else {
//                    // No drug name detected, show scanning overlay
//                    VStack(alignment: .center, spacing: 8) {
//                        Text("Memindai\nNama Obat")
//                            .font(.system(size: 38, weight: .bold))
//                            .foregroundColor(.white)
//                            .multilineTextAlignment(.center)
//                            .shadow(radius: 4)
//                            .padding(.horizontal, 16)
//                        Text("Coba beberapa sisi")
//                            .font(.title3)
//                            .foregroundColor(.white)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal, 16)
//                            .padding(.bottom, 8)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .center)
//                }
//            }
//            Spacer().frame(height: 100) // Space for buttons
//        }
//        .animation(.easeInOut, value: detectedDrugName)
//        .allowsHitTesting(cameraManager.modeOCR == .drug_name && detectedDrugName != nil)
//    }
//}

#Preview {
    ContentView()
}
