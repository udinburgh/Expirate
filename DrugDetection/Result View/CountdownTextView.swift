//
//  CountdownTextView.swift
//  Expirad
//
//  Created by Rifqi Rahman on 07/06/25.
//

import SwiftUI

enum TimeUnit{
    case hari
    case minggu
    case bulan
    case tahun
}

struct CountdownTextView: View {
    let timeValue: Int8
    let timeUnit : TimeUnit
    
    init(_ timeValue: Int8,_ timeUnit: TimeUnit){
        self.timeValue = timeValue
        self.timeUnit = timeUnit
    }
    
    var body: some View {
        let absoluteDays = abs(timeValue)
        let isOverdue = timeValue < 0
        
        VStack(spacing: 4) {
            Text("\(absoluteDays)")
                .font(.system(size: 80, weight: .bold))
                .accessibilityLabel(
                    isOverdue
                    ? "Terlewat \(absoluteDays) \(timeUnit)"
                    : "Tersisa \(absoluteDays) \(timeUnit)"//\(angkaKeTeks(absoluteDays)) hari"
                )
            
            Text(isOverdue ? "\(String(describing:timeUnit).capitalized) lalu" : "\(String(describing:timeUnit).capitalized) lagi")
                .font(.title3)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    CountdownTextView(15,TimeUnit.bulan)
//    VStack(spacing: 20) {
//        CountdownTextView(daysLeft: 30)
//        CountdownTextView(daysLeft: 10)
//        CountdownTextView(daysLeft: 2)
//        CountdownTextView(daysLeft: 0)
//        CountdownTextView(daysLeft: -5)
//    }
} 
