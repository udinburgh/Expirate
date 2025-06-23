//
//  ResultView.swift
//  Expirad
//
//  Created by Rifqi Rahman on 07/06/25.
//

import SwiftUI

private let RESULTVIEW_TTS_DELAY: Double = 1.0

struct ResultView: View {
    let detectedDate: Date?
    let detectedDrugName: String?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var ttsManager = ResultViewTTS()
    @State private var hasSpoken = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tombol kembali - tetap terpisah
   
            // Kontainer utama gabungan untuk aksesibilitas
            Group {
                if let date = detectedDate {
                    let daysLeft = calculateDaysLeft(from: date)
                    
                    if abs(daysLeft) > 45260  {
                        NoDataView()
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Tidak ada data. Tanggal kedaluwarsa tidak terdeteksi.")
                    }else{
                        let status = getExpiredStatus(for: daysLeft)
                        
                        ResultContentView(
                            detectedDate: date,
                            detectedDrugName: detectedDrugName
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            composeAccessibilityText(
                                daysLeft: daysLeft,
                                status: status,
                                date: date,
                                drugName: detectedDrugName
                            )
                        )
                    }

                } else {
                    NoDataView()
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Tidak ada data. Tanggal kedaluwarsa tidak terdeteksi.")
                }
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.primary)
        .navigationTitle("Hasil Pemindaian")
        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackButtonHidden(true)
        .onAppear {
            guard !hasSpoken else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + RESULTVIEW_TTS_DELAY) {
                if let date = detectedDate {
                    let daysLeft = calculateDaysLeft(from: date)
                    let status = getExpiredStatus(for: daysLeft)
                    ttsManager.speakExpirationResult(
                        daysLeft: daysLeft,
                        status: status,
                        date: date,
                        drugName: detectedDrugName
                    )
                } else {
                    ttsManager.speakNoDataMessage()
                }
            }
            hasSpoken = true
        }
        .onDisappear {
            ttsManager.stopSpeaking()
        }
    }

    // MARK: - Compose Accessibility Text
    func composeAccessibilityText(daysLeft: Int, status: ExpiredStatus, date: Date, drugName: String?) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMMM yyyy"
        let spokenDate = formatter.string(from: date)
        let drugText = drugName != nil ? "Obat \(drugName!). " : "Obat. "
        
        if daysLeft < 0 {
            let daysPast = abs(daysLeft)
            return "\(drugText)\(status.message). Obat sudah kedaluwarsa \(angkaKeTeks(daysPast)) hari yang lalu. Tanggal kedaluwarsa \(spokenDate). Jangan digunakan."
        } else if daysLeft == 0 {
            return "\(drugText)\(status.message). Obat kadaluwarsa hari ini, tanggal \(spokenDate)."
        } else if daysLeft <= 4 {
            return "\(drugText)\(status.message). Obat akan kedaluwarsa dalam \(angkaKeTeks(daysLeft)) hari lagi. Tanggal kedaluwarsa \(spokenDate)."
        } else if daysLeft <= 14 {
            return "\(drugText)\(status.message). Obat akan kedaluwarsa dalam \(angkaKeTeks(daysLeft)) hari lagi. Tanggal kedaluwarsa \(spokenDate)."
        } else {
            return "\(drugText)\(status.message). Obat masih aman. Akan kedaluwarsa dalam \(angkaKeTeks(daysLeft)) hari lagi, tanggal \(spokenDate)."
        }
    }
}

#Preview{
    ResultView(detectedDate: Date(), detectedDrugName: "Obat Rifqi")
}
