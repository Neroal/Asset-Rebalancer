import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var lang: LanguageViewModel

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text(lang.tabDashboard)
                }

            AssetsView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text(lang.tabAssets)
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(lang.tabSettings)
                }
        }
        .tint(.blue)
        .task {
            await portfolioVM.loadAll()
        }
    }
}
