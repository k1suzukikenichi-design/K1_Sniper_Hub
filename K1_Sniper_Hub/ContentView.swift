import SwiftUI
import FirebaseCore
import FirebaseFirestore

// --- 1. Firebase初期化用の設定 ---
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

struct ContentView: View {
    @State private var dxyIndex: Double = 50.4231
    @State private var obStatus: String = "READY"
    @State private var confluenceLevel: String = "CRITICAL"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // 軍用コンソール背景
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("K1 SNIPER HUB")
                    Spacer()
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("LIVE  14:05")
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                
                // DXY INDEX
                VStack {
                    Text("[ DXY_CUST INDEX ]").font(.caption)
                    Text("\(String(format: "%.4f", dxyIndex))")
                        .font(.system(size: 34, weight: .black, design: .monospaced))
                    Text("USD STRONG ▲").font(.caption).foregroundColor(.green)
                }
                .foregroundColor(.white)
                .padding()
                .border(Color.white.opacity(0.3))
                
                // CONFLUENCE CRITICAL
                if confluenceLevel == "CRITICAL" {
                    Text("!!! CONFLUENCE CRITICAL !!!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                }
                
                // TARGET OB STATUS
                HStack {
                    VStack(alignment: .leading) {
                        Text("[ TARGET OB STATUS ]").font(.caption2)
                        HStack {
                            Circle().fill(.green).frame(width: 10, height: 10)
                            Text(obStatus).font(.headline)
                        }
                        Text("BULL OB").font(.caption)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("OB HIGH: 150.200")
                        Text("OB MID : 149.850")
                        Text("OB LOW : 149.500")
                    }
                    .font(.system(size: 12, design: .monospaced))
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                
                // MACRO 3 CARDS
                HStack(spacing: 10) {
                    MacroCard(icon: "🏛️", title: "10Y YIELD", value: "4.250%")
                    MacroCard(icon: "💰", title: "GOLD", value: "2051.30")
                    MacroCard(icon: "📈", title: "S&P500", value: "5102.00")
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct MacroCard: View {
    var icon: String
    var title: String
    var value: String
    var body: some View {
        VStack {
            Text("\(icon) \(title)").font(.system(size: 8))
            Text(value).font(.system(size: 12, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.white.opacity(0.1))
        .foregroundColor(.white)
    }
}
