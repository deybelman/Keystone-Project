import Foundation
import CoreData
import SwiftUI

class DataController: ObservableObject {
    // Core Data container
    let container = NSPersistentContainer(name: "NotesDatabase")
    
    // Published property to notify views of changes
    @Published var savedTrips: [TripEntity] = []
    @Published var savedNotes: [JournalEntryEntity] = []
    
    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Failed to load data in DataController \(error.localizedDescription)")
            }
            self.fetchNotes()
            self.fetchTrips()
        }
    }
    
    func save() {
        do {
            try container.viewContext.save()
            fetchNotes() // Refresh the notes after saving
            fetchTrips()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Trip Operations
    
    func addTrip(name: String, startDate: Date, endDate: Date?, tripImage: Data? = nil) {
        let trip = TripEntity(context: container.viewContext)
        trip.id = UUID()
        trip.name = name
        trip.startDate = startDate
        trip.endDate = endDate
        trip.tripImage = tripImage
        save()
    }
    
    func deleteTrip(_ trip: TripEntity) {
        container.viewContext.delete(trip)
        save()
    }

    func fetchTrips() {
        let request = NSFetchRequest<TripEntity>(entityName: "TripEntity")
        do {
            savedTrips = try container.viewContext.fetch(request)
        } catch {
            print("Error fetching trips: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Journal Entry Operations
    
    func fetchNotes() {
        let request = NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
        
        do {
            savedNotes = try container.viewContext.fetch(request)
        } catch {
            print("Error fetching notes: \(error.localizedDescription)")
        }
    }
    
    func addNote(content: String) {
        let note = JournalEntryEntity(context: container.viewContext)
        note.id = UUID()
        note.content = content
        note.date = Date()
        
        save()
    }
    
    func editNote(_ note: JournalEntryEntity, newContent: String) {
        note.content = newContent
        save()
    }
    
    func deleteNote(_ note: JournalEntryEntity) {
        container.viewContext.delete(note)
        save()
    }
    
    func deleteNote(at offsets: IndexSet) {
        for index in offsets {
            let note = savedNotes[index]
            container.viewContext.delete(note)
        }
        save()
    }
    
    func editNote(_ note: JournalEntryEntity, newAttributedContent: NSAttributedString) {
        note.content = newAttributedContent.string
        note.attributedContent = try? newAttributedContent.data(
            from: NSRange(location: 0, length: newAttributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        save()
    }
    
    func addNote(attributedContent: NSAttributedString) {
        let note = JournalEntryEntity(context: container.viewContext)
        note.id = UUID()
        note.date = Date()
        note.content = attributedContent.string
        note.attributedContent = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        )
        save()
    }
    
    // MARK: - Image Operations
    
    func createImageGroup(for note: JournalEntryEntity, associatedID: String, associatedText: String) -> ImageGroupEntity {
        let imageGroup = ImageGroupEntity(context: container.viewContext)
        imageGroup.id = UUID()
        imageGroup.associatedID = associatedID
        imageGroup.associatedText = associatedText
        imageGroup.toNote = note
        
        save()
        
        return imageGroup
    }
    
    func addImageToGroup(imageData: Data, group: ImageGroupEntity) {
        let attachment = ImageAttachmentEntity(context: container.viewContext)
        attachment.id = UUID()
        attachment.imageData = imageData
        attachment.group = group

        save()
    }

    func fetchImageGroup(for note: JournalEntryEntity, associatedID: String) -> ImageGroupEntity? {
        let request = NSFetchRequest<ImageGroupEntity>(entityName: "ImageGroupEntity")
        request.predicate = NSPredicate(format: "toNote == %@ AND associatedID == %@", note, associatedID)
        request.fetchLimit = 1
        
        do {
            let results = try container.viewContext.fetch(request)
            return results.first
        } catch {
            print("Error fetching image group: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchImagesinGroup(_ imageGroup: ImageGroupEntity) -> [ImageAttachmentEntity] {
        let request = NSFetchRequest<ImageAttachmentEntity>(entityName: "ImageAttachmentEntity")
        request.predicate = NSPredicate(format: "group == %@", imageGroup)
        
        do {
            let results = try container.viewContext.fetch(request)
            return results
        } catch {
            print("Error fetching images in group: \(error.localizedDescription)")
            return []
        }
    }
}


    
