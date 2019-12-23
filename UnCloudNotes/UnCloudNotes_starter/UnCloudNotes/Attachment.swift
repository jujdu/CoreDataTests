//
//  Attachment.swift
//  UnCloudNotes
//
//  Created by Michael Sidoruk on 22.12.2019.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Attachment: NSManagedObject {
  @NSManaged var dateCreated: Date
  @NSManaged var note: Note?
}
