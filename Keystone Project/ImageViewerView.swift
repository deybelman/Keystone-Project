import SwiftUI

struct ImageViewerView: View {
    let note: NoteEntity?
    let associatedID: String?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        NavigationView {
            VStack{
                Image("test_image")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .navigationTitle("Image")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                    }
                Text(associatedID ?? "No ID")
            }
            
            
        }
    }
} 
