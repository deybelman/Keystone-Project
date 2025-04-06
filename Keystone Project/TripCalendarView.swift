import SwiftUI
import UIKit

struct TripCalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date?
    let startDate: Date
    let endDate: Date?
    let journalEntries: [JournalEntryEntity]
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        calendarView.delegate = context.coordinator
        
        // Create date interval from start and end dates
        if let end = endDate {
            calendarView.availableDateRange = DateInterval(start: startDate, end: end)
        } else {
            calendarView.availableDateRange = DateInterval(start: startDate, end: .distantFuture)
        }
        
        // Configure the calendar view
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.selectionBehavior = dateSelection
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Update decorations when journal entries change
        let decoratedDates = journalEntries.compactMap { entry -> DateComponents? in
            guard let date = entry.date,
                  let content = entry.content,
                  !content.isEmpty else { return nil }
            return Calendar.current.dateComponents([.year, .month, .day], from: date)
        }
        
        uiView.reloadDecorations(forDateComponents: decoratedDates, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate, UICalendarViewDelegate {
        var parent: TripCalendarView
        
        init(_ parent: TripCalendarView) {
            self.parent = parent
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            if let dateComponents = dateComponents,
               let date = Calendar.current.date(from: dateComponents) {
                parent.selectedDate = date
            }
        }
        
        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            // Check if this date has a non-empty journal entry
            if let date = Calendar.current.date(from: dateComponents),
               parent.journalEntries.contains(where: { entry in
                   guard let entryDate = entry.date,
                         let content = entry.content,
                         !content.isEmpty else { return false }
                   return Calendar.current.isDate(entryDate, inSameDayAs: date)
               }) {
                return .default()
            }
            return nil
        }
    }
}

//#Preview {
//    TripCalendarView(selectedDate: .constant(nil))
//} 
