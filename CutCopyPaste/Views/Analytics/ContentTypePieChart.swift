import SwiftUI
import Charts

struct ContentTypePieChart: View {
    let data: [ContentTypeDistribution]

    var body: some View {
        Chart(data) { item in
            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.5),
                angularInset: 2
            )
            .foregroundStyle(by: .value("Type", item.type.displayName))
            .cornerRadius(4)
        }
        .chartLegend(position: .bottom, alignment: .center, spacing: 8)
    }
}
