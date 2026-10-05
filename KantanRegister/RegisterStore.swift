import Foundation
import SwiftUI

struct Product: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var price: Int
}
struct CartLine: Identifiable, Codable {
    var product: Product
    var quantity: Int
    var id: UUID { product.id }
    var subtotal: Int { product.price * quantity }
}
struct Sale: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var lines: [CartLine]
    var total: Int { lines.reduce(0) { $0 + $1.subtotal } }
}
struct SavedData: Codable {
    var products: [Product]
    var sales: [Sale]
}
@MainActor final class RegisterStore: ObservableObject {
    @Published var products: [Product] = []
    @Published var sales: [Sale] = []
    @Published var cart: [CartLine] = []
    @Published var selectedID: UUID?
    @Published var saveError: String?
    private let fileURL: URL?
    init(fileURL: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("KantanRegister/data.json")) {
        self.fileURL = fileURL
        products = [Product(name: "アイテム1", price: 100), Product(name: "アイテム2", price: 300), Product(name: "アイテム3", price: 333), Product(name: "アイテム4", price: 444), Product(name: "りんご", price: 100), Product(name: "ゴリラ", price: 5000), Product(name: "ラッパ", price: 8000), Product(name: "パンツ", price: 10000)]
        if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let saved = try JSONDecoder().decode(SavedData.self, from: Data(contentsOf: fileURL))
                products = saved.products; sales = saved.sales
            } catch { saveError = "保存データを読み込めませんでした。\(error.localizedDescription)" }
        }
    }
    var total: Int { cart.reduce(0) { $0 + $1.subtotal } }
    var selected: CartLine? { cart.first { $0.id == selectedID } }
    func add(_ product: Product) {
        if let i = cart.firstIndex(where: { $0.id == product.id }) { if cart[i].quantity < 999 { cart[i].quantity += 1 } }
        else { cart.append(CartLine(product: product, quantity: 1)) }
        selectedID = product.id
    }
    func changeQuantity(_ delta: Int) {
        guard let i = cart.firstIndex(where: { $0.id == selectedID }) else { return }
        let value = cart[i].quantity + delta
        if value <= 0 { removeSelected() } else { cart[i].quantity = min(value, 999) }
    }
    func removeSelected() { cart.removeAll { $0.id == selectedID }; selectedID = cart.last?.id }
    func clear() { cart = []; selectedID = nil }
    @discardableResult func checkout() -> Bool {
        guard !cart.isEmpty else { return false }
        sales.append(Sale(lines: cart))
        guard save() else { sales.removeLast(); return false }
        clear(); return true
    }
    @discardableResult func save() -> Bool {
        guard let fileURL else { return true }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(SavedData(products: products, sales: sales)).write(to: fileURL, options: .atomic)
            return true
        } catch { saveError = "データを保存できませんでした。\(error.localizedDescription)"; return false }
    }
}
func yen(_ amount: Int) -> String { amount.formatted(.number.grouping(.automatic)) + "円" }
