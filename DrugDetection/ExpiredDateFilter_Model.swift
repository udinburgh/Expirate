//
//  ExpiredDateFilter.swift
//  DrugDetection
//
//  Created by Muhammad Hamzah Robbani on 16/06/25.
//

enum PositionExpiredDate{
    case previousLine
    case nextLine
}

enum MethodIdentifyExpiredLabelByKeyword{
    case search //search keyword
    case readPatternDate //keyword berupa pola dinamis, bukan literal string
    case readPatternCharacterType //pattern karakter, penandanya adalah: ! adalah huruf kapital, * adalah non kapital, @ adalah huruf(bisa kapital/non),$ adalah angka, & adalah karakter random, ~ adalah karakter spesial(selain huruf dan angka), _ adalah beberapa karakter yang random polanya (didepan/dibelakang pola)
    case special //ada kondisi tertentu yang identifynuya harus pakai kode produksi, biasanya kode produksi : (karater depan huruf kapital, lalu 5 angka), (karakter depan 3 huruf kapital, / , 2 angka, huruf kapital, 2 angka)
}

//ada expireddate yang polanya hanya terbaca jika 2 baris
//string yang terkandung adalah pola unik, bisa jadi di baris sebelum exprieddate atau setelahnya
enum SearchPatternMultilineExpiredDateLabel{
    case KODE_PRODUKSI//KODE PRODUKSI\nDD.MM.yy
    case Baik_Digunakan_Sebelum //Baik Digunakan Sebelum\nDD MM yyyy
    case MM_yyyy //MM yyyy\n$$$$$$$ //$ = angka kode produksi
    case DDMMyy //DDMMyy\n!$$$$$ //! = kapital
    
    
    var keyword: String {
        switch self {
            case .KODE_PRODUKSI: return "KODE PRODUKSI"
            case .Baik_Digunakan_Sebelum: return "Baik Digunakan Sebelum"
            case .MM_yyyy: return "$$$$$$$"
            case .DDMMyy: return "!$$$$$"
        }
    }
    
    var patternExpiredDate: String {
        switch self{
            case .KODE_PRODUKSI: return "DD.MM.yy"
            case .Baik_Digunakan_Sebelum: return "DD MM yyyy"
            case .MM_yyyy: return "MM yyyy"
            case .DDMMyy: return "DDMMyy"
        }
    }
    
    var methodIdentifyExpiredLabelByKeyword: MethodIdentifyExpiredLabelByKeyword{
        switch self{
            case .KODE_PRODUKSI,.Baik_Digunakan_Sebelum: return .search
            case .Baik_Digunakan_Sebelum: return .search
            case .MM_yyyy: return .readPatternCharacterType
            case .DDMMyy: return .readPatternCharacterType
        }
    }
    
    var positionExpiredDate: PositionExpiredDate {
        switch self {
            case .KODE_PRODUKSI: return .nextLine
            case .Baik_Digunakan_Sebelum: return .nextLine
            case .MM_yyyy: return .previousLine
            case .DDMMyy: return .previousLine
        }
    }
}

enum KeywordPositionToExpiredDate{
    case before //posisi keyword sebelum expired date
    case after //posisi keyword setelah expireddate
}

struct RequirementStringQualified{
    let letter_minimalCount: UInt8?//jumlah minimal sampai maksimal hurud
    let number_minimalCount: UInt8? //jumlah minimal sampai sampai maksimal angka
    let listSpecialCharacter_minimalCount: [Character:UInt8] //= [:] //misal jika pingin karakter titik minimal 3, maka ['.':3]
//    let keywordPositionToExpiredDate : KeywordPositionToExpiredDate
    
    init(number_minimalCount:UInt8?=nil, listSpecialCharacter_minimalCount:[Character:UInt8]=[:], letter_minimalCount:UInt8?=nil){
        self.letter_minimalCount = letter_minimalCount
        self.number_minimalCount = number_minimalCount
        self.listSpecialCharacter_minimalCount=listSpecialCharacter_minimalCount
//        self.keywordPositionToExpiredDate = keywordPositionToExpiredDate
    }
}

