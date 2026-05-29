import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    // Uygulamanın ana akışını (NutriLoadApp'te) başlatmak için kullanılacak closure
    let onCompletion: () -> Void
    
    var body: some View {
        if isActive {
            // Animasyon bitince ana görünüme (CoordinatorView) geçecek
            Color.clear.onAppear {
                onCompletion()
            }
        } else {
            VStack {
                VStack {
                    // Buraya AppIcon'ı veya SF Symbols'dan bir ikon koyabilirsin
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 80))
                        .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.55))
                    
                    Text("NutriLoad")
                        .font(.custom("Times New Roman", size: 36))
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.55))
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isActive = true
                }
            }
        }
    }
}
