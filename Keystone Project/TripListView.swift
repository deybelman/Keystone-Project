import SwiftUI

struct TripListView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingNewTripSheet = false
    
    private var sortedTrips: [TripEntity] {
        dataController.savedTrips.sorted { 
            ($0.startDate ?? Date()) > ($1.startDate ?? Date())
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedTrips) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        HStack {
                            if let imageData = trip.tripImage, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "airplane")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(trip.name ?? "Untitled Trip")
                                    .font(.headline)
                                
                                if let startDate = trip.startDate, let endDate = trip.endDate {
                                    Text(dateRangeText(from: startDate, to: endDate))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("My YOUJIs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewTripSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewTripSheet) {
                NewTripView()
            }
        }
    }
    
    private func dateRangeText(from startDate: Date, to endDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }
}
