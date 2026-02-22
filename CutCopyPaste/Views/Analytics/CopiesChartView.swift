import SwiftUI
import Charts

struct CopiesChartView: View {
    let data: [DailyCount]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Copies", item.count)
            )
            .foregroundStyle(.blue.gradient)
            .cornerRadius(3)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}
