//
//  EmployeePicture.swift
//  EmployeeDirectory
//
//  Created by Michael Sidoruk on 24.12.2019.
//  Copyright © 2019 Razeware. All rights reserved.
//

import UIKit
import CoreData

public class EmployeePicture: NSManagedObject {

}

extension EmployeePicture {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<EmployeePicture> {
    return NSFetchRequest<EmployeePicture>(entityName: "EmployeePicture")
  }
  
  @NSManaged public var picture: Data?
  @NSManaged public var employee: Employee?
}
