//
//  CameraViewModel.swift
//  DrugDetection
//
//  Created by Muhammad Hamzah Robbani on 16/06/25.
//

import SwiftUI
import AVFoundation
import Vision
import NaturalLanguage

enum ModeOCR{
    case drug_name
    case expired_date
}

class FlashlightManager {
    static func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else {
            print("Torch not available")
            return
        }

        do {
            try device.lockForConfiguration()
            
            if on {
                try device.setTorchModeOn(level: 1.0) // Turn ON with brightness
            } else {
                device.torchMode = .off // Only turn off
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used: \(error)")
        }
    }
}

class CameraView_Model: NSObject, ObservableObject {
    private var lastRecognizedPossibleExpiredDate = Date()
    private var lastDetectedExpiredDate = Date()
    @Published var modeOCR=ModeOCR.drug_name//drug_name
    
    @Published var detectedExpiredDate: Date? = nil{
        didSet{
            if let detectedExpiredDate = self.detectedExpiredDate {
                let showTime = 3 //second
                let timeRecognized = Date()
                self.lastDetectedExpiredDate = timeRecognized
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(showTime)) {
                    if self.detectedExpiredDate != nil && self.lastDetectedExpiredDate == timeRecognized {
                        DispatchQueue.main.sync {self.detectedExpiredDate=nil}
                    }//jika terakhir pendeteksian(ketemu gesture) dibawah 1 detik maka tidak diterima (agar tidak terlalu noise
                }
            }
        }
    }
    
    @Published var detectedDrugName: String? = nil {
            didSet {
                if detectedDrugName != nil {
                    print("✅ Drug name detected: \(detectedDrugName ?? "")")
                }
            }
        }
    
    @Published var isOCREnabled = true
    
    @Published var recognizedPossibleExpiredDate : String? = nil{
        didSet{
            if let recognizedPossibleExpiredDate = self.recognizedPossibleExpiredDate {
               
                let showTime = 3 //second
                let timeRecognized = Date()
                self.lastRecognizedPossibleExpiredDate = timeRecognized
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(showTime)) {
                    if self.recognizedPossibleExpiredDate != nil && self.lastRecognizedPossibleExpiredDate == timeRecognized {
                        DispatchQueue.main.sync {self.recognizedPossibleExpiredDate=nil}
                    }//jika terakhir pendeteksian(ketemu gesture) dibawah 1 detik maka tidak diterima (agar tidak terlalu noise
                }
            }
        }
    }
    
    
    
    private func extractDrugName(from texts: [String]) -> String? {
        let keywords = ["EXP", "EXPIRE", "BEST", "USE BY", "BB", "BBD", "ED", "E:", "B:", "KODE PRODUKSI", "BAIK DIGUNAKAN", "BATCH", "LOT", "MFG", "MANUFACTURED", "PRODUCED"]
        
        for line in texts {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedLine.count >= 3 else { continue }
            
            let upper = trimmedLine.uppercased()
            if keywords.contains(where: { upper.contains($0) }) { continue }
            
            let digitCount = trimmedLine.filter { $0.isNumber }.count
            let totalCount = trimmedLine.count
            if totalCount > 0 && Double(digitCount) / Double(totalCount) > 0.5 {
                continue
            }
            
            if upper.range(of: #"\d{1,2}[\/\.\-]\d{1,2}[\/\.\-]\d{2,4}"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"\d{6,8}"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"\d{4}"#, options: .regularExpression) != nil && upper.count <= 6 { continue }
            
            let cleanText = trimmedLine.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: "/", with: "")
            if cleanText.allSatisfy({ $0.isNumber }) { continue }
            
            let cleanedLine = trimmedLine.filter { !$0.isNumber && !$0.isPunctuation }
            guard cleanedLine.count >= 2 else { continue }
            
            let packagingText = ["MG", "ML", "GRAM", "TABLET", "CAPSULE", "SYRUP", "DROPS", "INJECTION", "CREAM", "GEL", "OINTMENT", "POWDER", "SUSPENSION", "SOLUTION", "TABLET", "KAPSUL", "SIRUP", "TETES", "INJEKSI", "KRIM", "SALEP", "BUBUK", "SUSPENSI", "LARUTAN"]
            if packagingText.contains(where: { upper.contains($0) }) && upper.count <= 15 { continue }
            
            if upper.range(of: #"\d+\s*MG"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"\d+\s*ML"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"\d+\s*GRAM"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"\d+\s*MG/ML"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"\d+\s*MG/GRAM"#, options: .regularExpression) != nil { continue }
            
            if upper.range(of: #"BATCH\s*#?\s*\d+"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"LOT\s*#?\s*\d+"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"NO\s*BATCH\s*#?\s*\d+"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"NO\s*LOT\s*#?\s*\d+"#, options: .regularExpression) != nil { continue }
            
            if upper.range(of: #"REG\s*#?\s*\d+"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"NAFDAC\s*#?\s*\d+"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"BPOM\s*#?\s*\d+"#, options: .regularExpression) != nil { continue }
            if upper.range(of: #"POM\s*#?\s*\d+"#, options: .regularExpression) != nil { continue }
            
            if upper.range(of: #"\d{10,}"#, options: .regularExpression) != nil { continue }
            
            let textOnly = trimmedLine.filter { !$0.isNumber && !$0.isPunctuation && !$0.isWhitespace }
            let numberOnly = trimmedLine.filter { $0.isNumber }
            
            if textOnly.count > numberOnly.count && textOnly.count >= 3 {
                let finalText = trimmedLine
                    .replacingOccurrences(of: "  ", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                return finalText
            }
            
            let finalText = trimmedLine
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return finalText
        }
        
        return nil
    }
    
    private func predictTags(from text: String, completion: @escaping ([String]?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let tokens = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

            guard let model = try? ExpiredDateLabel_Filter(configuration: MLModelConfiguration()).model,
                  let tagger = try? NLModel(mlModel: model) else {
                print("⚠️ Gagal memuat model exptagger24")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            var result: [(String, String)] = []
            var detectedDateTokens: [String] = []

            for token in tokens {
                let label = tagger.predictedLabel(for: token) ?? "O"
                result.append((token, label))
                
                if label == "date" {
                    detectedDateTokens.append(token)
                }
            }

//            if !detectedDateTokens.isEmpty {
//                let finalDate = detectedDateTokens.joined(separator: " ")
//                DispatchQueue.main.async {
//                    self.detectedExpiredDate = finalDate
//                    print("✅ Ditemukan tanggal kedaluwarsa: \(finalDate)")
//                }
//            }

            DispatchQueue.main.async {
                if detectedDateTokens.isEmpty { completion(nil)
                }else{ completion(detectedDateTokens) }
//                completion(result)
            }
        }
    }
        
//    private func predictTags(from text: String) -> [(token: String, label: String)]? {
//        let tokens = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
//
//        guard let model = try? ExpiredDateLabel_Filter(configuration: MLModelConfiguration()).model,
//              let tagger = try? NLModel(mlModel: model) else {
//            print("⚠️ Gagal memuat model exptagger24")
//            return nil
//        }
//
//        var result: [(String, String)] = []
//        var detectedDateTokens: [String] = []
//
//        for token in tokens {
//            let label = tagger.predictedLabel(for: token) ?? "O"
//            result.append((token, label))
//            
//            if label == "date" {
//                detectedDateTokens.append(token)
//            }
//        }
//
//        // Jika ada token dengan label date, hentikan proses dan tampilkan
//        if !detectedDateTokens.isEmpty {
//            let finalDate = detectedDateTokens.joined(separator: " ")
//            DispatchQueue.main.async {
//                self.detectedExpiredDate = finalDate
////                self.recognizedPossibleExpiredDate = nil // kosongkan agar tidak diulang
//            }
//            print("✅ Ditemukan tanggal kedaluwarsa: \(finalDate)")
//        }
//
//        return result
//    }

    private var lastProcessTime = Date.distantPast
    private let detectionEverySecond  = 0.1 //
    private var processDetecting = false

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "camera.queue")

    private var request: VNRecognizeTextRequest!

    private var isSessionRunning = false
    
    @Published var isFlashlightOn = false

    override init() {
        super.init()
        configure()
        setupVision()
    }
    
    private let listUniqueKeywordExpiredDateLabelSingleLine : [(String, KeywordPositionToExpiredDate,[RequirementStringQualified])] = [
        ("01134 ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:2)]), //ED :SEP 25
        ("ED :",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:2)]), //ED :SEP 25
        ("ED ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:8, listSpecialCharacter_minimalCount:[".":2])]), //ED 21.07.2025
        ("EXP D",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:8, listSpecialCharacter_minimalCount:[".":3, " ":2])]), //EXP D 26.09.2025
        ("EXP : ",KeywordPositionToExpiredDate.before,[
            RequirementStringQualified(number_minimalCount:5, listSpecialCharacter_minimalCount:[" ":4],letter_minimalCount: 3),//EXP : 5 Jun 2026
            RequirementStringQualified(number_minimalCount:6)//⁠EXP : 140625
        ]),
        ("EXP.: ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:6, listSpecialCharacter_minimalCount:["/":2])]),//⁠Exp.: 02/12/25
        ("EXP .",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:6, listSpecialCharacter_minimalCount:[".":1,"/":2])]),//EXP .07/06/25
        ("EXP ",KeywordPositionToExpiredDate.before,[
            RequirementStringQualified(number_minimalCount:4, listSpecialCharacter_minimalCount:[" ":2], letter_minimalCount: 3), //⁠EXP 19 JUN25
            RequirementStringQualified(number_minimalCount:8, listSpecialCharacter_minimalCount:[" ":3]),//⁠EXP 22 01 2026
            RequirementStringQualified(number_minimalCount:8, listSpecialCharacter_minimalCount:["/":2]), //EXP 25/11/2025
            RequirementStringQualified(number_minimalCount:6)//⁠EXP 221125
        ]),
        ("EXP: ",KeywordPositionToExpiredDate.before,[
            RequirementStringQualified(number_minimalCount:8, listSpecialCharacter_minimalCount:[" ":3]), //EXP: 05 01 2026
            RequirementStringQualified(number_minimalCount:8, listSpecialCharacter_minimalCount:[" ":1])//EXP: 19032026
        ]),
        ("EXP:",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:6, listSpecialCharacter_minimalCount:[".":2],letter_minimalCount: 6)]),//EXP:12.FEB.2026
        ("USE BY ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:6, listSpecialCharacter_minimalCount:["/":2])]), //USE BY 11/06/25
        ("BB : ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount: 6, listSpecialCharacter_minimalCount:[" ":4,".":2])]),//BB : 03. 01. 26
        ("BB ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount: 8, listSpecialCharacter_minimalCount:[" ":4])]),//⁠BB 02 01 2026
        ("Best Before ",KeywordPositionToExpiredDate.before,[
            RequirementStringQualified(number_minimalCount: 6, listSpecialCharacter_minimalCount: [" ":3]),//Best Before 02 2026
            RequirementStringQualified(number_minimalCount: 6),//Best Before 150325
        ]),
        ("BEST BEFORE ",KeywordPositionToExpiredDate.before,[
            RequirementStringQualified(number_minimalCount: 8, listSpecialCharacter_minimalCount: ["/":2]),//⁠BEST BEFORE 02/02/2025
            RequirementStringQualified(number_minimalCount: 6, listSpecialCharacter_minimalCount: [".":2])//BEST BEFORE 15.01.26
        ]),
        ("BEST BY ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:6,listSpecialCharacter_minimalCount: [" ":4],letter_minimalCount: 9)]), //BEST BY AUG 01 2025
        ("E : ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:6)]), //E : 310825
        ("E: ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:8,listSpecialCharacter_minimalCount: ["/":2])]), //E: 10/12/2025
        ("E ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:8,listSpecialCharacter_minimalCount: ["-":2])]), //E 10-12-2025
        ("BBD: ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:8,listSpecialCharacter_minimalCount: [".":2])]), //BBD: 15.07.2025
        ("B: ",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:8,listSpecialCharacter_minimalCount: [".":2])]), //B: 06.10.2025
        ("B.",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:8,listSpecialCharacter_minimalCount: [".":3])]), //B.10.12.2025
//        ("",KeywordPositionToExpiredDate.before,[RequirementStringQualified(number_minimalCount:8)]), //01052027
        
    ]
    
//    func isFlashlightOn() -> Bool {
//        guard let device = AVCaptureDevice.default(for: .video),
//              device.hasTorch else {
//            return false
//        }
//        return device.torchMode == .on
//    }
    
//    func toogleFlashlight(){
//        isFlashlightOn.toggle()
//        
//        print("flashlight \(isFlashlightOn)")
//        FlashlightManager.toggleTorch(on: isFlashlightOn)
//    }
//    
    func toogleFlashlight() {
        isFlashlightOn.toggle()
        FlashlightManager.toggleTorch(on: isFlashlightOn)
    }
    
    func OCR(_ status:Bool){
        isOCREnabled = status
        if !status{
            recognizedPossibleExpiredDate = nil
            detectedExpiredDate = nil
        }
    }
    
//    func detectDate(_ text: String)->Date? {
//        func normalizeDate() -> String {
//            
//            let cleaned = text.uppercased()
//                .replacingOccurrences(of: "[^A-Z0-9/.\\- ]", with: "", options: .regularExpression)
//                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
//                .trimmingCharacters(in: .whitespaces)
//
//            let monthMap: [String: Int] = [
//                "JAN": 1, "JANUARI": 1,
//                "FEB": 2, "FEBRUARI": 2,
//                "MAR": 3, "MARET": 3,
//                "APR": 4, "APRIL": 4,
//                "MAY": 5, "MEI": 5,
//                "JUN": 6, "JUNI": 6,
//                "JUL": 7, "JULI": 7,
//                "AUG": 8, "AGUSTUS": 8,
//                "SEP": 9, "SEPTEMBER": 9,
//                "OCT": 10, "OKT": 10,
//                "NOV": 11, "NOVEMBER": 11,
//                "DEC": 12, "DESEMBER": 12
//            ]
//
//            // Format seperti 15032025 (ddMMyyyy)
//            if let match = cleaned.range(of: "^\\d{8}$", options: .regularExpression) {
//                let str = String(cleaned[match])
//                let day = str.prefix(2)
//                let month = str.dropFirst(2).prefix(2)
//                let year = str.suffix(4)
//                return String(format: "%@/%@/%@", day as CVarArg, month as CVarArg, year as CVarArg)
//            }
//
//            // Format seperti 140625 (ddMMyy)
//            if let match = cleaned.range(of: "^\\d{6}$", options: .regularExpression) {
//                let str = String(cleaned[match])
//                let day = str.prefix(2)
//                let month = str.dropFirst(2).prefix(2)
//                let year = str.suffix(2)
//                return String(format: "%@/%@/20%@", day as CVarArg, month as CVarArg, year as CVarArg)
//            }
//
//            // Format seperti 2027 JANUARI 10 atau 10 JANUARI 2027 atau 2027 JAN 10 atau 10 JAN 2027
//            let parts = cleaned.components(separatedBy: " ").filter { !$0.isEmpty }
//            if parts.count == 3 {
//                let first = parts[0], second = parts[1], third = parts[2]
//
//                if let firstNum = Int(first), first.count == 4, let month = monthMap[second], let day = Int(third) {
//                    // Format: yyyy MMM dd
//                    return String(format: "%02d/%02d/%04d", day, month, firstNum)
//                } else if let day = Int(first), let month = monthMap[second], let year = Int(third) {
//                    // Format: dd MMM yyyy
//                    let fullYear = year < 100 ? 2000 + year : year
//                    return String(format: "%02d/%02d/%04d", day, month, fullYear)
//                }
//            }
//
//
//
//            // Format seperti JAN1027 atau 10JAN27
//            for (monthStr, monthNum) in monthMap.sorted(by: { $0.key.count > $1.key.count }) {
//                if let range = cleaned.range(of: monthStr) {
//                    let prefix = cleaned[..<range.lowerBound]
//                    let suffix = cleaned[range.upperBound...]
//
//                    let prefixStr = String(prefix)
//                    let suffixStr = String(suffix)
//
//                    if prefixStr.count == 2, let day = Int(prefixStr), suffixStr.count == 2 || suffixStr.count == 4, let year = Int(suffixStr) {
//                        let fullYear = year < 100 ? 2000 + year : year
//                        return String(format: "%02d/%02d/%04d", day, monthNum, fullYear)
//                    } else if suffixStr.count == 2, let day = Int(suffixStr), prefixStr.count == 2 || prefixStr.count == 4, let year = Int(prefixStr) {
//                        let fullYear = year < 100 ? 2000 + year : year
//                        return String(format: "%02d/%02d/%04d", day, monthNum, fullYear)
//                    }
//                }
//            }
//
//            // Format seperti 2025 JAN
//            for (monthStr, monthNum) in monthMap {
//                if cleaned.contains(monthStr) {
//                    let parts = cleaned.components(separatedBy: CharacterSet.whitespaces)
//                    if parts.count == 2 {
//                        if let year = Int(parts[0]), parts[1] == monthStr {
//                            return String(format: "01/%02d/%04d", monthNum, year)
//                        } else if let year = Int(parts[1]), parts[0] == monthStr {
//                            return String(format: "01/%02d/%04d", monthNum, year)
//                        }
//                    }
//                }
//            }
//
//            // Format seperti 2026.03 atau 03.2026
//            if let match = cleaned.range(of: "^\\d{4}[./-]\\d{2}$", options: .regularExpression) {
//                let comps = cleaned.components(separatedBy: CharacterSet(charactersIn: "./-"))
//                if comps.count == 2, let year = Int(comps[0]), let month = Int(comps[1]) {
//                    return String(format: "01/%02d/%04d", month, year)
//                }
//            }
//            if let match = cleaned.range(of: "^\\d{2}[./-]\\d{4}$", options: .regularExpression) {
//                let comps = cleaned.components(separatedBy: CharacterSet(charactersIn: "./-"))
//                if comps.count == 2, let month = Int(comps[0]), let year = Int(comps[1]) {
//                    return String(format: "01/%02d/%04d", month, year)
//                }
//            }
//
//            // Format dd MM yyyy or dd/MM/yyyy or dd-MM-yyyy or dd.MM.yy
//            let separators = ["/", "-", ".", " "]
//            for sep in separators {
//                let parts = cleaned.components(separatedBy: sep).filter { !$0.isEmpty }
//                if parts.count == 3 {
//                    if let day = Int(parts[0]), let month = Int(parts[1]), var year = Int(parts[2]) {
//                        if year < 100 { year += 2000 }
//                        return String(format: "%02d/%02d/%04d", day, month, year)
//                    }
//                } else if parts.count == 2 {
//                    if let month = Int(parts[0]), let year = Int(parts[1]) {
//                        return String(format: "01/%02d/%04d", month, year)
//                    }
//                }
//            }
//
//            return "Format tidak dikenali:\(text)"
//        }
//        
//   
//        let formatter = DateFormatter()
//        formatter.dateFormat = "dd/MM/yyyy"
//        formatter.locale = Locale(identifier: "en_US_POSIX") // Avoids issues with device settings
//        return formatter.date(from: normalizeDate())
//      
//    }
//    
    func detectDate(from text: String) -> Date? {
            let cleaned = text.uppercased()
                .replacingOccurrences(of: "[^A-Z0-9/.\\- ]", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            let monthMap: [String: Int] = [
                "JAN": 1, "JANUARI": 1,
                "FEB": 2, "FEBRUARI": 2,
                "MAR": 3, "MARET": 3,
                "APR": 4, "APRIL": 4,
                "MAY": 5, "MEI": 5,
                "JUN": 6, "JUNI": 6,
                "JUL": 7, "JULI": 7,
                "AUG": 8, "AGUSTUS": 8,
                "SEP": 9, "SEPTEMBER": 9,
                "OCT": 10, "OKT": 10,
                "NOV": 11, "NOVEMBER": 11,
                "DEC": 12, "DESEMBER": 12
            ]

            func makeDate(day: Int, month: Int, year: Int) -> Date? {
                var components = DateComponents()
                components.day = day
                components.month = month
                components.year = year
                return Calendar.current.date(from: components)
            }

            // 15032025
            if let _ = cleaned.range(of: "^\\d{8}$", options: .regularExpression) {
                let day = Int(cleaned.prefix(2))!
                let month = Int(cleaned.dropFirst(2).prefix(2))!
                let year = Int(cleaned.suffix(4))!
                return makeDate(day: day, month: month, year: year)
            }

            // 140625
            if let _ = cleaned.range(of: "^\\d{6}$", options: .regularExpression) {
                let day = Int(cleaned.prefix(2))!
                let month = Int(cleaned.dropFirst(2).prefix(2))!
                let year = 2000 + Int(cleaned.suffix(2))!
                return makeDate(day: day, month: month, year: year)
            }

            // yyyy MMM dd atau dd MMM yyyy
            let parts = cleaned.components(separatedBy: " ").filter { !$0.isEmpty }
            if parts.count == 3 {
                if let year = Int(parts[0]), let month = monthMap[parts[1]], let day = Int(parts[2]) {
                    return makeDate(day: day, month: month, year: year)
                } else if let day = Int(parts[0]), let month = monthMap[parts[1]], let y = Int(parts[2]) {
                    let year = y < 100 ? 2000 + y : y
                    return makeDate(day: day, month: month, year: year)
                }
            }

            // JAN1027 atau 10JAN27
            for (monthStr, monthNum) in monthMap.sorted(by: { $0.key.count > $1.key.count }) {
                if let range = cleaned.range(of: monthStr) {
                    let prefix = cleaned[..<range.lowerBound]
                    let suffix = cleaned[range.upperBound...]

                    if let day = Int(prefix), let year = Int(suffix) {
                        let fullYear = year < 100 ? 2000 + year : year
                        return makeDate(day: day, month: monthNum, year: fullYear)
                    } else if let day = Int(suffix), let year = Int(prefix) {
                        let fullYear = year < 100 ? 2000 + year : year
                        return makeDate(day: day, month: monthNum, year: fullYear)
                    }
                }
            }

            // 2025 JAN
            for (monthStr, monthNum) in monthMap {
                if cleaned.contains(monthStr) {
                    let comps = cleaned.components(separatedBy: " ")
                    if comps.count == 2 {
                        if let year = Int(comps[0]), comps[1] == monthStr {
                            return makeDate(day: 1, month: monthNum, year: year)
                        } else if let year = Int(comps[1]), comps[0] == monthStr {
                            return makeDate(day: 1, month: monthNum, year: year)
                        }
                    }
                }
            }

            // 2026.03 atau 03.2026
            let sepSet = CharacterSet(charactersIn: "./-")
            let comps = cleaned.components(separatedBy: sepSet)
            if comps.count == 2 {
                if let year = Int(comps[0]), let month = Int(comps[1]), year > 1900 {
                    return makeDate(day: 1, month: month, year: year)
                } else if let month = Int(comps[0]), let year = Int(comps[1]), year > 1900 {
                    return makeDate(day: 1, month: month, year: year)
                }
            }

            // dd/MM/yyyy, dd-MM-yyyy, dd.MM.yy
            for sep in ["/", "-", ".", " "] {
                let parts = cleaned.components(separatedBy: sep)
                if parts.count == 3,
                   let day = Int(parts[0]),
                   let month = Int(parts[1]),
                   var year = Int(parts[2]) {
                    if year < 100 { year += 2000 }
                    return makeDate(day: day, month: month, year: year)
                } else if parts.count == 2,
                          let month = Int(parts[0]),
                          let year = Int(parts[1]) {
                    return makeDate(day: 1, month: month, year: year)
                }
            }

            return nil
        }
    
    
    
    //list recognized text adalah daftar baris text yang terdeteksi
    private func textDetected(_ listRecognizedText: [String]){DispatchQueue.global(qos: .background).async {
        if listRecognizedText.isEmpty{return}
        
        if self.modeOCR == .drug_name {
            if let drugName = self.extractDrugName(from: listRecognizedText) {
                DispatchQueue.main.async {
                    self.detectedDrugName = drugName
                    print("✅ Drug name detected and set: \(drugName)")
                }
                return
            }
            else {
                print("test 123 \(listRecognizedText.joined(separator: "\n"))")
                return
            }
        }else{
            let listRecognizedNormalizedText = listRecognizedText.map { //jika ada spasi lebih dari 1 diantara 2 kata, maka akan diubah menjadi 1 spasi
                $0
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            
            
            //return kalimat single line yang kemungkinan expired date label tapi yang sudah berusaha dipotong agar tidak tercamopur data lain
            func detectPossibleExpiredDateLabelSingleLine(_ textDetectedSingleLine:String)->String?{
    //            print("checkPossibleExpiredDateLabelSingleLine= \(textDetectedSingleLine)")
                
                func qualifyRequirement(_ listRequirement: [RequirementStringQualified])->Bool{
                    func qualifyNumberMinimalCount(_ number_minimalCount: UInt8?)->Bool{
                        if let number_minimalCount = number_minimalCount {
                            let a = textDetectedSingleLine.filter { $0.isNumber }.count >= number_minimalCount //jika jumlah numeric karakter sama/lebih dari minimal maka qualify
                            if !a{print("'\(textDetectedSingleLine)' ❌ number \(number_minimalCount) [\(textDetectedSingleLine.filter { $0.isNumber }.count)]")}
                            return a
                        }else {return true} //jika nil maka tidak ada syarat minimal number
                    }
                    
                    func qualifyLetterMinimalCount(_ letter_minimalCount: UInt8?)->Bool{
                        if let letter_minimalCount = letter_minimalCount {
                            let a = textDetectedSingleLine.filter { $0.isLetter }.count >= letter_minimalCount //jika jumlah huruf karakter sama/lebih dari minimal maka qualify
                            if !a{print("'\(textDetectedSingleLine)' ❌ letter \(letter_minimalCount) [\(textDetectedSingleLine.filter { $0.isLetter }.count)]")}
                            return a
                        }else {return true} //jika nil maka tidak ada syarat minimal huruf
                    }
                    
                    func qualifySpecialCharacterMinimalCount(_ listSpecialCharacter_minimalCount: [Character:UInt8])->Bool{
                        return true //.simulasi, belum sempat
    //                        if listSpecialCharacter_minimalCount.count > 0 {
    //
    //                        }else{return true}
    //                        if let letter_minimalCount = letter_minimalCount {
    //                            return text.filter { $0.isLetter }.count >= letter_minimalCount //jika jumlah huruf karakter sama/lebih dari minimal maka qualify
    //                        }else {return true} //jika nil maka tidak ada syarat minimal huruf
                    }
                    
                    for requirement in listRequirement {
                        if qualifyLetterMinimalCount(requirement.letter_minimalCount) &&
                            qualifyNumberMinimalCount(requirement.number_minimalCount) &&
                            qualifySpecialCharacterMinimalCount(requirement.listSpecialCharacter_minimalCount) {return true}
                    }
                    return false
                }
                
                if self.recognizedPossibleExpiredDate == textDetectedSingleLine{return textDetectedSingleLine}
                
                for (keyword, keywordPositionToExpiredDate,requirement) in self.listUniqueKeywordExpiredDateLabelSingleLine{
                    if textDetectedSingleLine.contains(keyword){
                        if qualifyRequirement(requirement) {
    //                        print("terdeteksi '\(textDetectedSingleLine)' = \(keyword)")
                            if keywordPositionToExpiredDate == KeywordPositionToExpiredDate.before{
                                let result = String(textDetectedSingleLine[textDetectedSingleLine.range(of: keyword)!.lowerBound...])
    //                            print("terdeteksi1 '\(textDetectedSingleLine)' = \(keyword)")
                                return result
                            }else{return textDetectedSingleLine}
                            
                        }
                   }
                }
                return nil
            }
            
            func detectedPossibleExpiredDateLabel(_ possibleExpiredDateLabel:String){
    //            if let predictionResult = self.predictTags(from: recognizedPossibleExpiredDate) {
    //                print("Tagged Result: \(predictionResult)")
    //
    //                // ✅ Tambahkan logika deteksi final date di sini
    //                if let finalDateToken = predictionResult.first(where: { $0.label == "date" }) {
    //                    DispatchQueue.main.async {
    //                        print("✅ Detected Final Date: \(finalDateToken.token)")
    //                        // Bisa simpan ke state lain, misalnya:
    //                        self.detectedExpiredDate = finalDateToken.token
    //                    }
    //                    // Optional: langsung hentikan session kamera
    //                    self.stopSession()
    //                }
    //            }
                self.predictTags(from: possibleExpiredDateLabel) { result in
                    guard let result = result else {
                        print("❌ Failed to get prediction")
                        return
                    }

                    for dateString in result {
                        print("hasil terdeteksi \(dateString)")
                    }
                    
                    self.processDetecting = false
                    DispatchQueue.main.async {
                        print("dariML benar: [\(result.first!)]")
                        if let detectedExpiredDate = self.detectDate(from: result.first!) {
                            print("dariRegex benar: \(detectedExpiredDate) [\(result.first!)]")
                            self.detectedExpiredDate = detectedExpiredDate
    //                        print("hola33: \(detectedExpiredDate) [\(result.first!)]")
                        }else{
                            print("dariRegex salah: [\(result.first!)]")
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.recognizedPossibleExpiredDate=possibleExpiredDateLabel
                    //print("recognizedPossibleExpiredDate= '\(possibleExpiredDateLabel)'")
                }
            }
            
            self.processDetecting = true
            if listRecognizedNormalizedText.count>1{ //kemungkinan text exp date maksimal hanya 2 baris, dan akan dijadikan satu baris(enter diganti jadi spasi)
                func detect(){
                    listRecognizedNormalizedText.forEach { recognizedNormalizedText in
                        if let detectPossibleExpiredDateLabelSingleLine = detectPossibleExpiredDateLabelSingleLine(recognizedNormalizedText){
                            print("darifilter: \(detectPossibleExpiredDateLabelSingleLine)")
                            detectedPossibleExpiredDateLabel(detectPossibleExpiredDateLabelSingleLine)
                            return
                        }
                    }
                    self.processDetecting = false
                }
                
                detect()
                //simulasi aja, harusnya kalau lebih dari 1 baris harus cek pakai metode dual line possible expired date label
            }else{
                if let detectPossibleExpiredDateLabelSingleLine = detectPossibleExpiredDateLabelSingleLine(listRecognizedNormalizedText.first!){
                    detectedPossibleExpiredDateLabel(detectPossibleExpiredDateLabelSingleLine)
                }else{self.processDetecting = false}
            }
        }
        
                
        
        
        //self.processDetecting = false
//        if self.recognizedPossibleExpiredDate == recognizedText || recognizedText.isEmpty || !recognizedText.contains { $0.isNumber } { return } //jika text kosong/ tidak menggandung angka maka dianggap bukan tanggal
//
//        let digitCount  = recognizedText.filter { $0.isNumber }.count //mendeteksi ada berapa digit angka didalam string
//
//        func letterCount()->Int { recognizedText.filter { $0.isLetter }.count}
//
//        if digitCount >= 4 || (digitCount>=2 && letterCount()>=3){ //harusnya cari kata yang minimal 3 huruf atau jika kurang dari 3 huruf maka coba trim (mungkin kesalahan ocr membaca spasi)
//            DispatchQueue.main.async {
//                self.recognizedPossibleExpiredDate = recognizedText.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression) //menghapus semua space yang lebih dari satu(jika tergabung berada diantara 2 kata)
//            }
//        }
    }}

    
    
    func configure() {
        session.beginConfiguration()

        // Clear existing inputs and outputs (optional, for safety)
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            print("Failed to create camera input")
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else {
            print("Failed to add output")
            session.commitConfiguration()
            return
        }
        session.addOutput(output)

        session.commitConfiguration()
    }

    func setupVision() {
        request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.recognizedPossibleExpiredDate = nil
                    //self.recognizedText = ("Error: \(error.localizedDescription)"
                }
                return
            }
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let detectedStrings = observations
                .compactMap {$0.topCandidates(1).first}//harusnya filter dari sini ,kemungkinan topcandidate juga bisa salah
                .filter {$0.confidence > 0.8}// Only include confident results
                .map {$0.string}
            
            DispatchQueue.main.async {
                self.textDetected(detectedStrings)
            }
        }
        request.recognitionLevel = .accurate//.fast
        request.usesLanguageCorrection = true
    }

    func startSession() {
        guard !isSessionRunning else { return }  // guard to prevent multiple starts
        isSessionRunning = true

        queue.async {
            self.session.startRunning()
        }
    }

    func stopSession() {
        guard isSessionRunning else { return }
        isSessionRunning = false

        queue.async {
            self.session.stopRunning()
        }
    }
}

extension CameraView_Model: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {

        // Throttle: Process one frame every 0.5 seconds
        let now = Date()
        if now.timeIntervalSince(lastProcessTime) < detectionEverySecond  ||  processDetecting || !isOCREnabled { return }
        lastProcessTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            DispatchQueue.main.async {
                print("Vision error: \(error.localizedDescription)")
            }
        }
    }
}
