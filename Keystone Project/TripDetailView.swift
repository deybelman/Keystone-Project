import SwiftUI

struct TripDetailView: View {
    
    let trip: TripEntity
    @State private var showingEditSheet = false
    
    var body: some View {
        Text("Trip Detail View")
            .navigationTitle(trip.name ?? "Untitled Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditTripView(trip: trip)
            }
    }
}
