import Foundation
import SwiftUI
import UniformTypeIdentifiers

// UTF-8 BOM helps spreadsheet apps recognize Japanese text.
struct SalesCSV: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String
    init(sales: [Sale]) { text = Self.make(sales: sales) }
    init(configuration: ReadConfiguration) throws {
        text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
    static func cell(_ value: String) -> String {
        // Keep user-authored names from being interpreted as spreadsheet formulas.
        let safe = ["=", "+", "-", "@", "\t", "\r", "\n"].contains(where: { value.hasPrefix($0) }) ? "'" + value : value
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    static func make(sales: [Sale]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var rows = ["会計ID,日時,商品名,単価,数量,小計,会計合計"]
        for sale in sales {
            for line in sale.lines {
                rows.append([cell(sale.id.uuidString), cell(formatter.string(from: sale.date)), cell(line.product.name), String(line.product.price), String(line.quantity), String(line.subtotal), String(sale.total)].joined(separator: ","))
            }
        }
        return "\u{FEFF}" + rows.joined(separator: "\r\n") + "\r\n"
    }
}
// A predictable suggestion: round up to the next 1,000 yen, never below the total.
func suggestedCash(for total: Int) -> Int { guard total > 0 else { return 0 }; return ((total + 999) / 1000) * 1000 }
