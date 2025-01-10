import SwiftUI

struct NoteDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataController: DataController
    
    var note: FetchedResults<NoteEntity>.Element
    
    @State private var content = ""
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: note.date ?? Date())
    }
    
    var body: some View {
        TextEditor(text: $content)
            .padding(.horizontal)
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dataController.editNote(note, newContent: content)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .onAppear {
                content = note.content ?? ""
            }
    }
}
