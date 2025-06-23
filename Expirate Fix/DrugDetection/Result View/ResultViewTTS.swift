//
//  ResultViewTTS.swift
//  Expirad
//
//  Created by Rifqi Rahman on 07/06/25.
//

import Foundation
import SwiftUI
import UIKit

class ResultViewTTS: ObservableObject {
    
    func speakExpirationResult(daysLeft: Int, status: ExpiredStatus, date: Date, drugName: String?) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "id_ID")
        dateFormatter.dateFormat = "d MMMM yyyy"
        let spokenDate = dateFormatter.string(from: date)
        
        let drugPrefix = drugName != nil ? "Obat \(drugName!). " : "Obat. "
        
        var message: String
        if daysLeft < 0 {
            let daysPast = abs(daysLeft)
            message = "\(drugPrefix)\(status.message). Obat sudah kadaluarsa \(angkaKeTeks(daysPast)) hari yang lalu. Tanggal kadaluarsa \(spokenDate). Jangan gunakan obat ini."
        } else if daysLeft == 0 {
            message = "\(drugPrefix)\(status.message). Obat kadaluarsa hari ini, tanggal \(spokenDate). Sebaiknya jangan digunakan."
        } else if daysLeft <= 4 {
            message = "\(drugPrefix)\(status.message). Obat akan kadaluarsa dalam \(angkaKeTeks(daysLeft)) hari lagi. Tanggal kadaluarsa \(spokenDate). Segera gunakan."
        } else if daysLeft <= 14 {
            message = "\(drugPrefix)\(status.message). Obat akan kadaluarsa dalam \(angkaKeTeks(daysLeft)) hari lagi. Tanggal kadaluarsa \(spokenDate)."
        } else {
            message = "\(drugPrefix)\(status.message). Obat masih aman digunakan. Akan kadaluarsa dalam \(angkaKeTeks(daysLeft)) hari lagi, tanggal \(spokenDate)."
        }

        postVoiceOverAnnouncement(message)
    }
    
    func speakNoDataMessage() {
        let message = "Tidak ada data. Tanggal kadaluarsa tidak dapat dibaca dari gambar. Silakan coba lagi dengan memfokuskan kamera pada tanggal kadaluarsa yang lebih jelas."
        postVoiceOverAnnouncement(message)
    }
    
    func stopSpeaking() {
        UIAccessibility.post(notification: .announcement, argument: "")
    }
    
    private func postVoiceOverAnnouncement(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning else {
            print("VoiceOver tidak aktif: \(message)")
            return
        }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
