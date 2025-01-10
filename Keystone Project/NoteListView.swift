import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingNewNote = false
    
    private func truncatedContent(_ content: String?) -> String {
        guard let content = content, !content.isEmpty else { return "New Note" }
        let maxLength = 30
        if content.count > maxLength {
            let index = content.index(content.startIndex, offsetBy: maxLength)
            return String(content[..<index]) + "..."
        }
        return content
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataController.savedNotes.sorted(by: { $0.date ?? Date() > $1.date ?? Date() })) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VStack(alignment: .leading) {
                            Text(truncatedContent(note.content))
                                .font(.headline)
                            Text(note.date ?? Date(), style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: dataController.deleteNote)
            }
            .navigationTitle("My Trip Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewNote = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NewNoteView()
        }
    }
}

#Preview {
    NoteListView()
}
