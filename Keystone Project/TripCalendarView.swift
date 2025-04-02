import SwiftUI
import UIKit

struct TripCalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date?
    let startDate: Date
    let endDate: Date?
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        
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
        // Update the view if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate {
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
    }
}

//#Preview {
//    TripCalendarView(selectedDate: .constant(nil))
//} 
