import SwiftUI

struct DateFormatting {
    static func tripDateRangeText(from startDate: Date, to endDate: Date?) -> AttributedString {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let startDateString = dateFormatter.string(from: startDate)
        if let endDate = endDate {
            return AttributedString("\(startDateString) - \(dateFormatter.string(from: endDate))")
        } else {
            let baseString = "\(startDateString) - ∞"
            var attributedString = AttributedString(baseString)
            
            // Find the range of the infinity symbol
            if let infinityRange = attributedString.range(of: "∞") {
                attributedString[infinityRange].font = .system(size: 18)
            }
            
            return attributedString
        }
    }
} 