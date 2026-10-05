import SwiftUI

private enum RegisterTheme {
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.17)
    static let accent = Color(red: 0.05, green: 0.43, blue: 0.40)
    static let muted = Color(white: 0.93)
    static let radius: CGFloat = 12
}
private struct RegisterButtonStyle: ButtonStyle {
    var secondary = false
    var fontSize: CGFloat = 18
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: fontSize, weight: .semibold))
            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.85)
            .foregroundStyle(secondary ? RegisterTheme.ink : .white)
            .padding(.horizontal, 10).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(secondary ? RegisterTheme.muted : RegisterTheme.ink,
                        in: RoundedRectangle(cornerRadius: RegisterTheme.radius))
            .contentShape(RoundedRectangle(cornerRadius: RegisterTheme.radius))
            .opacity(!isEnabled ? 0.4 : configuration.isPressed ? 0.7 : 1)
    }
}
struct ContentView: View {
    @EnvironmentObject var store: RegisterStore
    @State private var screen = "home"
    var body: some View {
        Group {
            switch screen {
            case "register": RegisterView { screen = "home" }
            case "settings": SettingsView { screen = "home" }
            case "report": ReportView { screen = "home" }
            default:
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 32) {
                            Image("AppBrand").resizable().frame(width: 88, height: 88)
                                .clipShape(RoundedRectangle(cornerRadius: 20)).accessibilityHidden(true)
                            Text("かんたんレジ").font(.system(size: 32, weight: .bold))
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: geometry.size.width >= 600 ? 3 : 1), spacing: 12) {
                                menuButton("設定", detail: "商品名・価格", symbol: "slider.horizontal.3", id: "settings")
                                menuButton("日報", detail: "売上集計", symbol: "chart.bar", id: "report")
                                menuButton("レジ", detail: "会計を開始", symbol: "yensign.circle", id: "register")
                            }
                            HStack(spacing: 24) {
                                Link("サポート", destination: URL(string: "https://koshikawa-masato.github.io/kantan-register-ios/support.html")!)
                                Link("プライバシーポリシー", destination: URL(string: "https://koshikawa-masato.github.io/kantan-register-ios/privacy.html")!)
                            }.font(.footnote)
                        }.frame(maxWidth: 900)
                            .padding(24).frame(maxWidth: .infinity)
                            .frame(minHeight: geometry.size.height)
                    }
                }.background(.white)
            }
        }.tint(RegisterTheme.accent).foregroundStyle(RegisterTheme.ink)
            .alert("保存エラー", isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.saveError = nil } })) {
                Button("閉じる") { store.saveError = nil }
            } message: { Text(store.saveError ?? "") }
    }
    private func menuButton(_ title: String, detail: String, symbol: String, id: String) -> some View {
        Button { screen = id } label: {
            HStack(spacing: 16) {
                Image(systemName: symbol).font(.system(size: 26)).frame(width: 32).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 22, weight: .bold))
                    Text(detail).font(.system(size: 16, weight: .medium))
                }
                Spacer(minLength: 0)
            }.padding(10)
        }.buttonStyle(RegisterButtonStyle()).accessibilityIdentifier(id)
    }
}
private enum PaymentMode: String, Identifiable {
    case calculation, checkout
    var id: String { rawValue }
}
struct RegisterView: View {
    @EnvironmentObject var store: RegisterStore
    var onExit: () -> Void
    @State private var paymentMode: PaymentMode?
    @State private var showClear = false
    @State private var showExit = false
    @State private var completed = false
    var body: some View {
        GeometryReader { geometry in
            let spacious = geometry.size.width >= 600
            let inset: CGFloat = spacious ? 20 : 12
            let short = geometry.size.height < 450
            VStack(spacing: short ? 6 : 10) {
                customerDisplay(spacious: spacious)
                    .frame(height: max(64, (geometry.size.height - inset * 2) * (short ? 0.28 : 0.40)))
                    .rotationEffect(.degrees(180))
                Rectangle().fill(RegisterTheme.ink).frame(height: 2)
                HStack(spacing: 8) {
                    Button("終了") { if store.cart.isEmpty { onExit() } else { showExit = true } }
                        .accessibilityIdentifier("exit-register")
                    Spacer(minLength: 0)
                    Text("オペレータ操作").font(.system(size: spacious ? 20 : 15, weight: .semibold))
                    Spacer(minLength: 0)
                    Button("釣り銭計算") { paymentMode = .calculation }.disabled(store.cart.isEmpty)
                }.font(.system(size: spacious ? 18 : 15, weight: .medium)).buttonStyle(.bordered)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(store.products) { product in
                            Button { store.add(product) } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name).lineLimit(2)
                                    Text(yen(product.price)).monospacedDigit().font(.system(size: spacious ? 18 : 15))
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }.buttonStyle(RegisterButtonStyle(fontSize: spacious ? 22 : 17))
                                .accessibilityIdentifier("product-\(product.name)")
                        }
                    }
                }.accessibilityIdentifier("product-list")
                VStack(spacing: 8) {
                    if let line = store.selected {
                        Text("選択中  \(line.product.name) × \(line.quantity)")
                            .lineLimit(1).minimumScaleFactor(0.8)
                    } else { Text("商品を選択してください").foregroundStyle(.secondary) }
                    HStack(spacing: 6) { cartControls(spacious: spacious) }
                }.font(.system(size: spacious ? 18 : 15))
            }.padding(inset)
        }.background(.white)
        .sheet(item: $paymentMode) { mode in PaymentView(confirming: mode == .checkout) { completed = true }.id(mode.id) }
        .alert("全ての商品を取り消しますか？", isPresented: $showClear) {
            Button("取消", role: .destructive) { store.clear() }; Button("戻る", role: .cancel) {}
        }
        .alert("会計途中で終了しますか？", isPresented: $showExit) {
            Button("商品を取り消して終了", role: .destructive) { store.clear(); onExit() }; Button("戻る", role: .cancel) {}
        }
        .alert("会計を記録しました", isPresented: $completed) { Button("次の会計", role: .cancel) {} }
    }
    @ViewBuilder private func cartControls(spacious: Bool) -> some View {
        Group {
            Button("−") { store.changeQuantity(-1) }.disabled(store.selected == nil).accessibilityIdentifier("minus")
                .frame(maxWidth: spacious ? 100 : 48)
            Button("＋") { store.changeQuantity(1) }.disabled(store.selected == nil).accessibilityIdentifier("plus")
                .frame(maxWidth: spacious ? 100 : 48)
            Button("商品取消") { store.removeSelected() }.disabled(store.selected == nil)
                .accessibilityIdentifier("remove-selected")
            Button("全て取消") { showClear = true }.disabled(store.cart.isEmpty)
                .accessibilityIdentifier("clear-cart")
        }.buttonStyle(RegisterButtonStyle(secondary: true, fontSize: spacious ? 18 : 14))
        Button("会計確定") { paymentMode = .checkout }.disabled(store.cart.isEmpty)
            .buttonStyle(RegisterButtonStyle(fontSize: spacious ? 20 : 15)).accessibilityIdentifier("checkout")
    }
    private func customerDisplay(spacious: Bool) -> some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let quantityWidth: CGFloat = spacious ? 60 : 36
                let priceWidth: CGFloat = spacious ? 140 : min(110, geometry.size.width * 0.32)
                ScrollView {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Text("商品名").frame(maxWidth: .infinity, alignment: .leading)
                            Text("数量").frame(width: quantityWidth)
                            Text("小計").frame(width: priceWidth, alignment: .trailing)
                        }.font(.system(size: spacious ? 18 : 14, weight: .semibold))
                            .padding(8).background(RegisterTheme.muted, in: RoundedRectangle(cornerRadius: 6))
                        ForEach(store.cart) { line in
                            Button { store.selectedID = line.id } label: {
                                HStack(spacing: 8) {
                                    Text(line.product.name).frame(maxWidth: .infinity, alignment: .leading)
                                    Text("\(line.quantity)").frame(width: quantityWidth)
                                    Text(yen(line.subtotal)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
                                        .frame(width: priceWidth, alignment: .trailing)
                                }.padding(8).background(store.selectedID == line.id ? RegisterTheme.muted : .clear,
                                                         in: RoundedRectangle(cornerRadius: 6))
                            }.buttonStyle(.plain)
                        }
                    }
                    // Customer coordinates: bottom alignment leaves space beside the operator after rotation.
                    .frame(minHeight: geometry.size.height, alignment: .bottom)
                }.defaultScrollAnchor(.bottom)
            }
            Text("合計  \(yen(store.total))").font(.system(size: spacious ? 32 : 26, weight: .bold))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.75).accessibilityIdentifier("total")
        }.font(.system(size: spacious ? 22 : 16)).foregroundStyle(RegisterTheme.ink)
    }
}

struct PaymentView: View {
    @EnvironmentObject var store: RegisterStore
    @Environment(\.dismiss) private var dismiss
    @State private var received = ""
    @State private var replaceOnInput = true
    var confirming: Bool
    var onComplete: () -> Void
    private var amount: Int { Int(received) ?? 0 }
    private let keys = ["7", "8", "9", "4", "5", "6", "1", "2", "3", "0", "00", "消去"]
    var body: some View {
        VStack(spacing: 0) {
            ScrollView { paymentContent }
            if confirming {
                Divider()
                Button("会計を確定して記録") {
                    if store.checkout() { dismiss(); onComplete() }
                }.buttonStyle(RegisterButtonStyle()).disabled(amount < store.total || store.cart.isEmpty)
                    .accessibilityIdentifier("confirm-payment")
                    .frame(maxWidth: 640).padding(.horizontal, 20).padding(.vertical, 12)
            }
        }.background(.white).foregroundStyle(RegisterTheme.ink)
            .onAppear { received = String(suggestedCash(for: store.total)); replaceOnInput = true }
            .presentationDetents([.large])
    }
    private var paymentContent: some View {
        VStack(spacing: 16) {
            Text("釣り銭計算").font(.system(size: 26, weight: .bold))
            Text("合計  \(yen(store.total))").font(.system(size: 20, weight: .medium))
            HStack { Text("お預かり"); Spacer(); Text(yen(amount)).monospacedDigit().accessibilityIdentifier("received") }
                .font(.system(size: 22, weight: .medium))
            Divider()
            Text("\(amount >= store.total ? "釣り銭" : "不足")  \(yen(abs(amount - store.total)))")
                .font(.system(size: 30, weight: .bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                .accessibilityIdentifier("change")
            Text("合計を1,000円単位で切り上げて自動入力").font(.footnote).foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(keys, id: \.self) { key in
                    Button(key) {
                        if key == "消去" { received = ""; replaceOnInput = false }
                        else {
                            if replaceOnInput { received = ""; replaceOnInput = false }
                            if received.count + key.count <= 9 { received += key }
                        }
                    }.buttonStyle(RegisterButtonStyle(secondary: true, fontSize: 22))
                        .accessibilityIdentifier("key-" + key)
                }
            }
            HStack(spacing: 8) {
                Button("計算し直す") { received = String(suggestedCash(for: store.total)); replaceOnInput = true }
                Button("閉じる") { dismiss() }
            }.buttonStyle(RegisterButtonStyle(secondary: true))
        }.padding(20).frame(maxWidth: 640).frame(maxWidth: .infinity)
    }
}
struct SettingsView: View {
    @EnvironmentObject var store: RegisterStore
    var onExit: () -> Void
    @State private var editing: Product?
    @State private var adding = false
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.products) { product in
                    Button { editing = product } label: { LabeledContent(product.name, value: yen(product.price)) }.foregroundStyle(.primary)
                }.onDelete { offsets in let previous = store.products; store.products.remove(atOffsets: offsets); if !store.save() { store.products = previous } }
            }.listStyle(.insetGrouped).navigationTitle("商品名・価格").navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("戻る", action: onExit) }
                ToolbarItem(placement: .primaryAction) { Button("商品を追加") { adding = true } }
            }.sheet(item: $editing) { ProductEditor(product: $0) }
                .sheet(isPresented: $adding) { ProductEditor(product: Product(name: "", price: 0)) }
        }
    }
}
struct ProductEditor: View {
    @EnvironmentObject var store: RegisterStore
    @Environment(\.dismiss) private var dismiss
    var product: Product
    @State private var name = ""
    @State private var price = ""
    var body: some View {
        NavigationStack {
            Form {
                TextField("商品名", text: $name)
                TextField("価格（円）", text: $price).keyboardType(.numberPad)
                    .onChange(of: price) { _, value in price = String(value.filter(\.isNumber).prefix(7)) }
            }.navigationTitle("商品設定").navigationBarTitleDisplayMode(.inline).onAppear { name = product.name; price = String(product.price) }.toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("戻る") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var updated = product; updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines); updated.price = Int(price) ?? 0
                        let previous = store.products
                        if let i = store.products.firstIndex(where: { $0.id == product.id }) { store.products[i] = updated } else { store.products.append(updated) }
                        if store.save() { dismiss() } else { store.products = previous }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Int(price) == nil)
                }
            }
        }
    }
}
struct ReportView: View {
    @EnvironmentObject var store: RegisterStore
    var onExit: () -> Void
    @State private var date = Date()
    @State private var exporting = false
    @State private var exportDocument = SalesCSV(sales: [])
    @State private var exportError: String?
    private var daily: [Sale] { store.sales.filter { Calendar.current.isDate($0.date, inSameDayAs: date) } }
    var body: some View {
        NavigationStack {
            List {
                DatePicker("日付", selection: $date, displayedComponents: .date).environment(\.locale, Locale(identifier: "ja_JP"))
                Button("この日の売上をCSV書き出し") { exportDocument = SalesCSV(sales: daily); exporting = true }.disabled(daily.isEmpty)
                LabeledContent("会計件数", value: "\(daily.count)件")
                LabeledContent("売上合計", value: yen(daily.reduce(0) { $0 + $1.total })).font(.title2.bold())
                Section("会計履歴") {
                    if daily.isEmpty { Text("この日の売上はありません") }
                    ForEach(daily.reversed()) { sale in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack { Text(sale.date, style: .time); Spacer(); Text(yen(sale.total)).bold() }
                            Text(sale.lines.map { "\($0.product.name) × \($0.quantity)" }.joined(separator: "、")).foregroundStyle(.secondary)
                        }
                    }
                }
            }.fileExporter(isPresented: $exporting, document: exportDocument, contentType: .commaSeparatedText, defaultFilename: "売上-" + date.formatted(.iso8601.year().month().day().dateSeparator(.dash))) { result in
                if case .failure(let error) = result { exportError = error.localizedDescription }
            }.alert("CSVを書き出せませんでした", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) { Button("閉じる") { exportError = nil } } message: { Text(exportError ?? "") }
            .listStyle(.insetGrouped).navigationTitle("日報・売上集計").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("戻る", action: onExit) } }
        }
    }
}
