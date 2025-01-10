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
    
    private var sortedNotes: [NoteEntity] {
        dataController.savedNotes.sorted { $0.date ?? Date() > $1.date ?? Date() }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(sortedNotes) { note in
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
                .onDelete { indexSet in
                    // Convert selected indices from sorted array to original array
                    let notesToDelete = indexSet.map { sortedNotes[$0] }
                    for note in notesToDelete {
                        dataController.deleteNote(note)
                    }
                }
            }
            .navigationTitle("My Trip Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NoteDetailView(note: nil)) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    NoteListView()
}
