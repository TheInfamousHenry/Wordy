import Foundation
import CoreData

@objc(WordEntity)
public class WordEntity: NSManagedObject {
}

extension WordEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordEntity> {
        return NSFetchRequest<WordEntity>(entityName: "WordEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var word: String?
    @NSManaged public var definition: String?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var timesReviewed: Int16
    @NSManaged public var lastReviewed: Date?
}
