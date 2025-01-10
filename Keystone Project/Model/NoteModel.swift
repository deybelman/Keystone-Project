import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var date: Date
    
    init(id: UUID = UUID(), title: String, content: String, date: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
    }
}

class NoteStore: ObservableObject {
    @Published var notes: [Note] = []
    
    init() {
        // Load saved notes here (e.g., from UserDefaults or Core Data)
    }
    
    func addNote(_ note: Note) {
        notes.append(note)
        // Save notes here
    }
    
    func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        // Save notes here
    }
}
