import Foundation
import Markdown

/// Converts Markdown (CommonMark + GitHub Flavored Markdown) into HTML.
enum MarkdownRenderer {
    static func html(from markdown: String) -> String {
        let document = Document(parsing: markdown)
        var renderer = HTMLRenderer()
        renderer.visit(document)
        return renderer.result
    }
}

/// A Markup walker that produces properly escaped HTML.
private struct HTMLRenderer: MarkupWalker {
    var result = ""
    private var columnAlignments: [Table.ColumnAlignment?] = []
    private var inTableHead = false

    // MARK: Blocks

    mutating func visitParagraph(_ paragraph: Paragraph) {
        result += "<p>"
        descendInto(paragraph)
        result += "</p>\n"
    }

    mutating func visitHeading(_ heading: Heading) {
        result += "<h\(heading.level)>"
        descendInto(heading)
        result += "</h\(heading.level)>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result += "<blockquote>\n"
        descendInto(blockQuote)
        result += "</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let lang = codeBlock.language.map { " class=\"language-\(escape($0))\"" } ?? ""
        result += "<pre><code\(lang)>\(escape(codeBlock.code))</code></pre>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr>\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += html.rawHTML
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        let start = orderedList.startIndex == 1 ? "" : " start=\"\(orderedList.startIndex)\""
        result += "<ol\(start)>\n"
        descendInto(orderedList)
        result += "</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        let isTaskList = unorderedList.listItems.contains { $0.checkbox != nil }
        result += isTaskList ? "<ul class=\"task-list\">\n" : "<ul>\n"
        descendInto(unorderedList)
        result += "</ul>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) {
        if let checkbox = listItem.checkbox {
            result += "<li class=\"task-list-item\"><input type=\"checkbox\" disabled"
            if checkbox == .checked { result += " checked" }
            result += "> "
        } else {
            result += "<li>"
        }
        descendInto(listItem)
        result += "</li>\n"
    }

    // MARK: Tables

    mutating func visitTable(_ table: Table) {
        columnAlignments = table.columnAlignments
        result += "<table>\n"
        descendInto(table)
        result += "</table>\n"
        columnAlignments = []
    }

    mutating func visitTableHead(_ tableHead: Table.Head) {
        inTableHead = true
        result += "<thead>\n<tr>\n"
        descendInto(tableHead)
        result += "</tr>\n</thead>\n"
        inTableHead = false
    }

    mutating func visitTableBody(_ tableBody: Table.Body) {
        guard !tableBody.isEmpty else { return }
        result += "<tbody>\n"
        descendInto(tableBody)
        result += "</tbody>\n"
    }

    mutating func visitTableRow(_ tableRow: Table.Row) {
        result += "<tr>\n"
        descendInto(tableRow)
        result += "</tr>\n"
    }

    mutating func visitTableCell(_ tableCell: Table.Cell) {
        let tag = inTableHead ? "th" : "td"
        var attrs = ""
        let index = tableCell.indexInParent
        if index < columnAlignments.count, let alignment = columnAlignments[index] {
            switch alignment {
            case .left: attrs = " style=\"text-align:left\""
            case .center: attrs = " style=\"text-align:center\""
            case .right: attrs = " style=\"text-align:right\""
            }
        }
        if tableCell.colspan > 1 { attrs += " colspan=\"\(tableCell.colspan)\"" }
        if tableCell.rowspan > 1 { attrs += " rowspan=\"\(tableCell.rowspan)\"" }
        result += "<\(tag)\(attrs)>"
        descendInto(tableCell)
        result += "</\(tag)>\n"
    }

    // MARK: Inlines

    mutating func visitText(_ text: Markdown.Text) {
        result += escape(text.string)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += "<em>"
        descendInto(emphasis)
        result += "</em>"
    }

    mutating func visitStrong(_ strong: Strong) {
        result += "<strong>"
        descendInto(strong)
        result += "</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += "<del>"
        descendInto(strikethrough)
        result += "</del>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(escape(inlineCode.code))</code>"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        result += inlineHTML.rawHTML
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "<br>\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += "\n"
    }

    mutating func visitLink(_ link: Markdown.Link) {
        var attrs = " href=\"\(escape(link.destination ?? ""))\""
        if let title = link.title, !title.isEmpty { attrs += " title=\"\(escape(title))\"" }
        result += "<a\(attrs)>"
        descendInto(link)
        result += "</a>"
    }

    mutating func visitImage(_ image: Markdown.Image) {
        var attrs = " src=\"\(escape(image.source ?? ""))\" alt=\"\(escape(image.plainText))\""
        if let title = image.title, !title.isEmpty { attrs += " title=\"\(escape(title))\"" }
        result += "<img\(attrs)>"
    }

    mutating func visitSymbolLink(_ symbolLink: SymbolLink) {
        result += "<code>\(escape(symbolLink.destination ?? ""))</code>"
    }

    // MARK: Helpers

    private func escape(_ string: String) -> String {
        var out = ""
        out.reserveCapacity(string.utf8.count)
        for ch in string {
            switch ch {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            default: out.append(ch)
            }
        }
        return out
    }
}
