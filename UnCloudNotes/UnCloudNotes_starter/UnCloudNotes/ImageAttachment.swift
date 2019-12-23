//
//  ImageAttachment.swift
//  UnCloudNotes
//
//  Created by Michael Sidoruk on 23.12.2019.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import UIKit
import CoreData

class ImageAttachment: Attachment {
  @NSManaged var image: UIImage?
  @NSManaged var width: Float
  @NSManaged var height: Float
  @NSManaged var caption: String
}
