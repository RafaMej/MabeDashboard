// DashboardService.swift
// Protocol defining the dashboard data contract.
// Provides MockDashboardService (preview/development) and LiveDashboardService stub (production).

import Foundation
import Combine

// MARK: — Protocol

protocol DashboardServiceProtocol {
    func fetchKPIs() async throws -> [KPIMetric]
    func fetchHeatmapData(range: DateInterval) async throws -> [HeatmapCell]
    func fetchSentimentTrend(range: DateInterval) async throws -> [SentimentDataPoint]
    func fetchRecentQueries(limit: Int) async throws -> [QueryRecord]
    func fetchModelEfficiency() async throws -> [ModelEfficiency]
}

// MARK: — Mock Service (Development / Previews)

final class MockDashboardService: DashboardServiceProtocol {

    private let simulatedLatency: TimeInterval

    init(simulatedLatency: TimeInterval = 0.3) {
        self.simulatedLatency = simulatedLatency
    }

    func fetchKPIs() async throws -> [KPIMetric] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return KPIMetric.mockData
    }

    func fetchHeatmapData(range: DateInterval) async throws -> [HeatmapCell] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return HeatmapCell.mockData()
    }

    func fetchSentimentTrend(range: DateInterval) async throws -> [SentimentDataPoint] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return SentimentDataPoint.mockData()
    }

    func fetchRecentQueries(limit: Int) async throws -> [QueryRecord] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return Array(QueryRecord.mockData.prefix(limit))
    }

    func fetchModelEfficiency() async throws -> [ModelEfficiency] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return ModelEfficiency.mockData
    }
}

// MARK: — Live Service Stub (Production)

/// INTEGRATION POINT: Configure baseURL, authentication headers, and response decoding here.
/// Each method should map to your actual REST/GraphQL/WebSocket endpoints.
final class LiveDashboardService: DashboardServiceProtocol {

    // INTEGRATION POINT: Replace with your API base URL
    private let baseURL = URL(string: "https://api.nexushr.example.com/v1")!
    private let session: URLSession

    // INTEGRATION POINT: Inject your auth token / API key via environment or keychain
    private var authToken: String { ProcessInfo.processInfo.environment["NEXUSHR_API_TOKEN"] ?? "" }

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func authorizedRequest(for path: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    func fetchKPIs() async throws -> [KPIMetric] {
        // INTEGRATION POINT: Decode from /kpis endpoint
        let _ = authorizedRequest(for: "kpis")
        throw URLError(.unsupportedURL) // Replace with actual URLSession data task
    }

    func fetchHeatmapData(range: DateInterval) async throws -> [HeatmapCell] {
        // INTEGRATION POINT: Decode from /heatmap?from=&to= endpoint
        throw URLError(.unsupportedURL)
    }

    func fetchSentimentTrend(range: DateInterval) async throws -> [SentimentDataPoint] {
        // INTEGRATION POINT: Decode from /sentiment/trend endpoint
        throw URLError(.unsupportedURL)
    }

    func fetchRecentQueries(limit: Int) async throws -> [QueryRecord] {
        // INTEGRATION POINT: Decode from /queries?limit= endpoint
        throw URLError(.unsupportedURL)
    }

    func fetchModelEfficiency() async throws -> [ModelEfficiency] {
        // INTEGRATION POINT: Decode from /models/efficiency endpoint
        throw URLError(.unsupportedURL)
    }
}
