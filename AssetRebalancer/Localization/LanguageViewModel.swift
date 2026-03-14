import Foundation

// MARK: - Language
enum AppLanguage: String, CaseIterable {
    case zh = "zh"
    case en = "en"

    var displayName: String {
        switch self {
        case .zh: return "繁體中文"
        case .en: return "English"
        }
    }
}

// MARK: - Language ViewModel
@MainActor
class LanguageViewModel: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "zh"
        self.language = AppLanguage(rawValue: saved) ?? .zh
    }

    // MARK: - Translation Helper
    func t(_ zh: String, _ en: String) -> String {
        language == .zh ? zh : en
    }
}

// MARK: - Localized Strings
extension LanguageViewModel {
    // Tab Bar
    var tabDashboard: String { t("總覽", "Dashboard") }
    var tabAssets: String { t("資產", "Assets") }
    var tabSettings: String { t("設定", "Settings") }

    // Dashboard
    var totalAssets: String { t("總資產", "Total Assets") }
    var currentAllocation: String { t("目前配置", "Current Allocation") }
    var targetAllocation: String { t("目標配置", "Target Allocation") }
    var deviation: String { t("偏差", "Deviation") }
    var rebalanceNeeded: String { t("需要再平衡", "Rebalance Needed") }
    var balanced: String { t("配置平衡", "Balanced") }
    var rebalanceSuggestions: String { t("再平衡建議", "Rebalance Suggestions") }
    var buy: String { t("買入", "Buy") }
    var sell: String { t("賣出", "Sell") }
    var hold: String { t("持有", "Hold") }
    var pullToRefresh: String { t("下拉更新股價", "Pull to refresh prices") }

    // Assets
    var addAsset: String { t("新增資產", "Add Asset") }
    var stocks: String { t("股票", "Stocks") }
    var bonds: String { t("債券", "Bonds") }
    var cash: String { t("現金", "Cash") }
    var symbol: String { t("代號", "Symbol") }
    var shares: String { t("股數", "Shares") }
    var amount: String { t("金額", "Amount") }
    var price: String { t("價格", "Price") }
    var market: String { t("市場", "Market") }
    var delete: String { t("刪除", "Delete") }
    var edit: String { t("編輯", "Edit") }
    var save: String { t("儲存", "Save") }
    var cancel: String { t("取消", "Cancel") }
    var name: String { t("名稱", "Name") }

    // Settings
    var settings: String { t("設定", "Settings") }
    var language_: String { t("語言", "Language") }
    var deviationThreshold: String { t("偏差門檻", "Deviation Threshold") }
    var signOut: String { t("登出", "Sign Out") }
    var account: String { t("帳號", "Account") }
    var targetAllocationSetting: String { t("目標資產配置", "Target Asset Allocation") }

    // Login
    var welcome: String { t("資產再平衡", "Asset Rebalancer") }
    var loginSubtitle: String { t("追蹤你的投資組合配置", "Track your portfolio allocation") }
    var signInWithGoogle: String { t("使用 Google 登入", "Sign in with Google") }

    // Errors
    var errorOccurred: String { t("發生錯誤", "Error Occurred") }
}
