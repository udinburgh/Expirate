//
//  Help_View.swift
//  DrugDetection
//
//  Created by Muhammad Hamzah Robbani on 18/06/25.
//

import SwiftUI

struct Help_View: View {
    var body: some View {
        VStack{
            Spacer()
            Text("Expirate").font(.title).bold().padding(.bottom,20)
//            Spacer(minLength:0)
            Text("Aplikasi yang membantu teman netra untuk membaca nama dan tanggal kadaluarsa obat.\n\n1.Buka aplikasi, 2. arahkan kamera ke obat,\n3. Lalu konfirmasi obat yang terdeteksi.")
            .multilineTextAlignment(.center)
            .font(.title2)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal,20)
            Spacer()
        }
        
    }
}

#Preview {
    Help_View()
}
