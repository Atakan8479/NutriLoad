import SwiftUI

struct DashboardView: View {
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Tipografik olarak güçlü ve temiz bir başlık
                Text("NutriLoad Analitik")
                    .font(.custom("Times New Roman", size: 32))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Spacer()
                
                // İleride buraya Swift Charts ile çizilmiş, kategorik renk paletlerine sahip grafikler gelecek.
                Text("Grafik Alanı")
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Merkezi Coordinator üzerinden yönlendirme yapan buton
                Button(action: {
                    coordinator.navigate(to: .logWorkout)
                }) {
                    Text("Yeni Antrenman Ekle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        // Akademik bir ciddiyet katan, desatüre çelik mavisi
                        .background(Color(red: 0.2, green: 0.35, blue: 0.55))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
}
