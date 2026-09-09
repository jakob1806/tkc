import Foundation
import UIKit

/// §18 Export: erzeugt eine übersichtliche chronologische Liste für einen Zeitraum,
/// wahlweise als PDF, CSV, Text oder zum direkten Kopieren.
enum ExportField: String, CaseIterable, Identifiable {
    case caption, platform, contentType, concert, publishTime, status, assignee, assets, links, notes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .caption: return "Caption"
        case .platform: return "Plattform"
        case .contentType: return "Content-Typ"
        case .concert: return "Konzert"
        case .publishTime: return "Veröffentlichungszeit"
        case .status: return "Status"
        case .assignee: return "Verantwortlicher"
        case .assets: return "Assets"
        case .links: return "Links"
        case .notes: return "Notizen"
        }
    }
}

enum ExportService {
    /// Chronologisch sortierte, nach Tag gruppierte Textdarstellung wie im Lastenheft-Beispiel.
    static func plainText(items: [ContentItem], fields: Set<ExportField>) -> String {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: items) { calendar.startOfDay(for: $0.date) }
        var lines: [String] = []
        for day in grouped.keys.sorted() {
            lines.append(day.formatted(date: .numeric, time: .omitted))
            for item in grouped[day]!.sorted(by: { ($0.publishTime ?? $0.date) < ($1.publishTime ?? $1.date) }) {
                if fields.contains(.publishTime), let time = item.publishTime {
                    lines.append(time.formatted(date: .omitted, time: .shortened))
                }
                if fields.contains(.platform) { lines.append(item.platform.displayName) }
                lines.append(item.title)
                if fields.contains(.concert), let concert = item.concert { lines.append("Konzert: \(concert.title)") }
                if fields.contains(.contentType) { lines.append("Typ: \(item.contentType.displayName)") }
                if fields.contains(.status) { lines.append("Status: \(item.status.displayName)") }
                if fields.contains(.assignee), let assignee = item.assignee, !assignee.isEmpty { lines.append("Verantwortlich: \(assignee)") }
                if fields.contains(.caption), let caption = item.caption, !caption.isEmpty { lines.append("Caption: \(caption)") }
                if fields.contains(.links), let links = item.links, !links.isEmpty { lines.append("Links: \(links)") }
                if fields.contains(.assets), !item.assets.isEmpty { lines.append("Assets: \(item.assets.map(\.title).joined(separator: ", "))") }
                if fields.contains(.notes), let notes = item.notes, !notes.isEmpty { lines.append("Notizen: \(notes)") }
                lines.append("")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func csv(items: [ContentItem], fields: Set<ExportField>) -> String {
        var header = ["Datum", "Titel"]
        header += ExportField.allCases.filter(fields.contains).map(\.displayName)
        var rows: [[String]] = [header]

        let sorted = items.sorted { ($0.publishTime ?? $0.date) < ($1.publishTime ?? $1.date) }
        for item in sorted {
            var row = [item.date.formatted(date: .numeric, time: .omitted), item.title]
            for field in ExportField.allCases where fields.contains(field) {
                row.append(csvValue(for: item, field: field))
            }
            rows.append(row)
        }
        return rows.map { row in
            row.map { field -> String in
                let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\""
            }.joined(separator: ";")
        }.joined(separator: "\n")
    }

    private static func csvValue(for item: ContentItem, field: ExportField) -> String {
        switch field {
        case .caption: return item.caption ?? ""
        case .platform: return item.platform.displayName
        case .contentType: return item.contentType.displayName
        case .concert: return item.concert?.title ?? ""
        case .publishTime: return item.publishTime?.formatted(date: .omitted, time: .shortened) ?? ""
        case .status: return item.status.displayName
        case .assignee: return item.assignee ?? ""
        case .assets: return item.assets.map(\.title).joined(separator: ", ")
        case .links: return item.links ?? ""
        case .notes: return item.notes ?? ""
        }
    }

    /// Erzeugt ein einfaches, mehrseitiges PDF mit der chronologischen Liste.
    static func pdf(items: [ContentItem], fields: Set<ExportField>, title: String) -> Data {
        let pageWidth: CGFloat = 595.2 // A4 @ 72dpi
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let text = plainText(items: items, fields: fields)
        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let bodyFont = UIFont.systemFont(ofSize: 11)

        return renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: titleFont])
            y += 30

            let lines = text.components(separatedBy: "\n")
            for line in lines {
                if y > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
                let attributes: [NSAttributedString.Key: Any] = line.count < 12 && !line.contains(":") && !line.isEmpty && !line.contains(".")
                    ? [.font: UIFont.boldSystemFont(ofSize: 12)]
                    : [.font: bodyFont]
                line.draw(at: CGPoint(x: margin, y: y), withAttributes: attributes)
                y += 16
            }
        }
    }
}
