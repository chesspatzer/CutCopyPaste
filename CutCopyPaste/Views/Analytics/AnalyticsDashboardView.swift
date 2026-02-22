import SwiftUI
import Charts

struct AnalyticsDashboardView: View {
    @EnvironmentObject var appState: AppState

    @State private var dailyCounts: [DailyCount] = []
    @State private var typeDistribution: [ContentTypeDistribution] = []
    @State private var hourlyData: [HourlyDistribution] = []
    @State private var topApps: [AppUsage] = []
    @State private var totalItems = 0
    @State private var todayItems = 0
    @State private var avgPerDay = 0.0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Clipboard Analytics")
                        .font(.title2.weight(.bold))
                    Spacer()
                }

                // Summary cards
                HStack(spacing: 12) {
                    StatCardView(icon: "doc.on.doc", label: "Total Items", value: "\(totalItems)")
                    StatCardView(icon: "calendar.badge.clock", label: "Today", value: "\(todayItems)")
                    StatCardView(icon: "chart.line.uptrend.xyaxis", label: "Avg/Day", value: String(format: "%.1f", avgPerDay))
                }

                // Daily copies chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Copies Per Day")
                        .font(.headline)
                    CopiesChartView(data: dailyCounts)
                        .frame(height: 180)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))

                HStack(spacing: 16) {
                    // Content type distribution
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content Types")
                            .font(.headline)
                        ContentTypePieChart(data: typeDistribution)
                            .frame(height: 180)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))

                    // Peak hours
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Peak Hours")
                            .font(.headline)
                        Chart(hourlyData) { item in
                            BarMark(
                                x: .value("Hour", "\(item.hour):00"),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                        .frame(height: 180)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
                }

                // Top apps
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Source Apps")
                        .font(.headline)
                    ForEach(topApps) { app in
                        HStack {
                            Text(app.appName)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(app.count)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.accentColor.opacity(0.3))
                                    .frame(width: barWidth(for: app.count, in: geo.size.width))
                            }
                            .frame(width: 100, height: 12)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
            }
            .padding(24)
        }
        .task { await loadData() }
    }

    private func loadData() async {
        dailyCounts = await appState.analyticsService.copiesPerDay(lastDays: 30)
        typeDistribution = await appState.analyticsService.contentTypeDistribution()
        hourlyData = await appState.analyticsService.peakUsageHours()
        topApps = await appState.analyticsService.topSourceApps(limit: 8)
        totalItems = await appState.analyticsService.totalItemsStored()
        todayItems = await appState.analyticsService.totalItemsToday()
        avgPerDay = await appState.analyticsService.averageCopiesPerDay(lastDays: 30)
    }

    private func barWidth(for count: Int, in maxWidth: CGFloat) -> CGFloat {
        let maxCount = topApps.first?.count ?? 1
        return maxWidth * CGFloat(count) / CGFloat(maxCount)
    }
}
