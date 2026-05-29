import SwiftUI
import Charts

struct TonnageChartView: View {
    // Grafiğin çizeceği veriler (Tarih ve Hacim)
    let workouts: [WorkoutEntity]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Antrenman Hacmi (Tonnage)")
                .font(.custom("Times New Roman", size: 16))
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                .padding(.bottom, 5)
            
            Chart {
                ForEach(workouts, id: \.id) { workout in
                    if let date = workout.date {
                        // Veri bilimi standartlarında Bar grafiği
                        BarMark(
                            x: .value("Tarih", date, unit: .day),
                            y: .value("Tonaj", workout.totalTonnage)
                        )
                        // Seaborn kütüphanesinin klasik 'steel blue' tonu
                        .foregroundStyle(Color(red: 0.3, green: 0.45, blue: 0.69))
                        .cornerRadius(4)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel()
                        .font(.custom("Times New Roman", size: 10))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day().month())
                        .font(.custom("Times New Roman", size: 10))
                }
            }
            .frame(height: 220)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
