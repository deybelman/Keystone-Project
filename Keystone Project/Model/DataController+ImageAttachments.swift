import Foundation
import CoreData

extension DataController {
    // CRUD operations for image attachments
    func addImageAttachment(for note: NoteEntity, imageData: Data, associatedText: String, associatedID: String) {
        let attachment = ImageAttachmentEntity(context: container.viewContext)
        attachment.id = UUID()
        attachment.imageData = imageData
        attachment.attachedAt = Date()
        attachment.associatedText = associatedText
        attachment.associatedID = associatedID
        attachment.note = note
        
        save()
    }

    func fetchImageAttachments(for note: NoteEntity) -> [ImageAttachmentEntity] {
        guard let attachments = note.attachments?.allObjects as? [ImageAttachmentEntity] else {
            return []
        }
        return attachments
    }
}