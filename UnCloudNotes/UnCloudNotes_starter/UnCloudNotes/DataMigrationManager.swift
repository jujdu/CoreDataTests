//
//  DataMigrationManager.swift
//  UnCloudNotes
//
//  Created by Michael Sidoruk on 23.12.2019.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import CoreData

class DataMigrationManager {
  let enableMigrations: Bool
  let modelName: String
  let storeName: String = "UnCloudNotesDataModel"
  var stack: CoreDataStack {
    guard enableMigrations, !store(at: storeUrl, isCompatibleWithModel: currentModel) else { return CoreDataStack(modelName: modelName)}
    
    performMigration()
    return CoreDataStack(modelName: modelName)
  }
  
  init(modelNamed: String, enableMigrations: Bool = false) {
    self.modelName = modelNamed
    self.enableMigrations = enableMigrations
  }
  
  private func store(at storeUrl: URL, isCompatibleWithModel model: NSManagedObjectModel) -> Bool {
    let storeMetadata = metadataForStoreAtURL(storeUrl: storeUrl)
    return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: storeMetadata)
  }
  
  private func metadataForStoreAtURL(storeUrl: URL) -> [String: Any] {
    let metadata: [String: Any]
    do {
    metadata = try NSPersistentStoreCoordinator
      .metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeUrl, options: nil)
    } catch {
      metadata = [:]
      print("Error retrieving metadata for store at URL: \(storeUrl): \(error)")
    }
    return metadata
  }
  
  private var applicationSupportURL: URL {
    let path = NSSearchPathForDirectoriesInDomains(
      .applicationSupportDirectory,
      .userDomainMask, true)
      .first
    return URL(fileURLWithPath: path!)
  }
  
  private lazy var storeUrl: URL = {
    let storeFileName = "\(self.storeName).sqlite"
    return URL(fileURLWithPath: storeFileName, relativeTo: self.applicationSupportURL)
  }()
  
  private var storeModel: NSManagedObjectModel? {
    return NSManagedObjectModel.modelVersionsFor(modelNamed: modelName)
      .filter { self.store(at: storeUrl, isCompatibleWithModel: $0) }
      .first
  }
  
  private lazy var currentModel: NSManagedObjectModel = .model(named: self.modelName)
  
  func performMigration() {
    if !currentModel.isVersion4 {
      fatalError("Can only handle migrations to verstion 4!")
    }
    
    if let storeModel = self.storeModel {
      if storeModel.isVersion1 {
        let destinationModel = NSManagedObjectModel.version2
        
        migrateStoreAt(url: storeUrl,
                       fromModel: storeModel,
                       toModel: destinationModel)
        
        performMigration()
      } else if storeModel.isVersion2 {
        let destinationModel = NSManagedObjectModel.version3
        let mappingModel = NSMappingModel(from: nil,
                                          forSourceModel: storeModel,
                                          destinationModel: destinationModel)
        
        migrateStoreAt(url: storeUrl,
                       fromModel: storeModel,
                       toModel: destinationModel,
                       mappingModel: mappingModel)
        
        performMigration()
      } else if storeModel.isVersion3 {
        let destinationModel = NSManagedObjectModel.version4
        let mappingModel = NSMappingModel(from: nil,
                                          forSourceModel: storeModel,
                                          destinationModel: destinationModel)
        
        migrateStoreAt(url: storeUrl,
                       fromModel: storeModel,
                       toModel: destinationModel,
                       mappingModel: mappingModel)
      }
    }
  }
  
  private func migrateStoreAt(url storeUrl: URL, fromModel from: NSManagedObjectModel, toModel to: NSManagedObjectModel, mappingModel: NSMappingModel? = nil) {
    //1
    let migrationManager = NSMigrationManager(sourceModel: from, destinationModel: to)
    //2
    var migrationMappingModel: NSMappingModel
    if let mappingModel = mappingModel {
      migrationMappingModel = mappingModel
    } else {
      migrationMappingModel = try! NSMappingModel
        .inferredMappingModel(forSourceModel: from, destinationModel: to)
    }
    //3
    let targetUrl = storeUrl.deletingLastPathComponent()
    let destinationName = storeUrl.lastPathComponent + "~1"
    let destinationUrl = targetUrl.appendingPathComponent(destinationName)
    
    print("From Model: \(from.entityVersionHashesByName)")
    print("To Model: \(to.entityVersionHashesByName)")
    print("Migrating store \(storeUrl) to \(destinationUrl)")
    print("Mapping model: \(String(describing: mappingModel))")
    //4
    let success: Bool
    do {
      try migrationManager.migrateStore(from: storeUrl,
                                        sourceType: NSSQLiteStoreType,
                                        options: nil,
                                        with: migrationMappingModel,
                                        toDestinationURL: destinationUrl,
                                        destinationType: NSSQLiteStoreType,
                                        destinationOptions: nil)
      success = true
    } catch {
      success = false
      print("Migration failed: \(error)")
    }
    
    //5
    if success {
      print("Migration Completed Successfully")
      
      let fileManager = FileManager.default
      do {
        try fileManager.removeItem(at: storeUrl)
        try fileManager.moveItem(at: destinationUrl, to: storeUrl)
      } catch {
        print("Error migration \(error)")
      }
    }
  }
  
  
}

//MARK: - ExtentionNSManagedObjectModel
extension NSManagedObjectModel {
  private class func modelUrls(in modelFolder: String) -> [URL] {
    return Bundle.main.urls(forResourcesWithExtension: "mom", subdirectory: "\(modelFolder).momd") ?? []
  }
  
  class func modelVersionsFor(modelNamed modelName: String) -> [NSManagedObjectModel] {
    return modelUrls(in: modelName).compactMap(NSManagedObjectModel.init)
  }
  
  class func uncloudNotesModel(named modelName: String) -> NSManagedObjectModel {
    let model = modelUrls(in: "UnCloudNotesDataModel")
      .filter { $0.lastPathComponent == "\(modelName).mom"}
      .first
      .flatMap(NSManagedObjectModel.init)
    return model ?? NSManagedObjectModel()
  }
  
  class func model(named modelName: String, in bundle: Bundle = .main) -> NSManagedObjectModel {
    return bundle.url(forResource: modelName, withExtension: "momd").flatMap(NSManagedObjectModel.init) ?? NSManagedObjectModel()
  }
  
  //MARK: - Version 1
  class var version1: NSManagedObjectModel {
    return uncloudNotesModel(named: "UnCloudNotesDataModel")
  }
  
  var isVersion1: Bool {
    return self == type(of: self).version1
  }
  
  //MARK: - Version 2
  class var version2: NSManagedObjectModel {
    return uncloudNotesModel(named: "UnCloudNotesDataModel v2")
  }
  
  var isVersion2: Bool {
    return self == type(of: self).version2
  }
  
  //MARK: - Version 3
  class var version3: NSManagedObjectModel {
    return uncloudNotesModel(named: "UnCloudNotesDataModel v3")
  }
  
  var isVersion3: Bool {
    return self == type(of: self).version3
  }
  
  //MARK: - Version 4
  class var version4: NSManagedObjectModel {
    return uncloudNotesModel(named: "UnCloudNotesDataModel v4")
  }
  
  var isVersion4: Bool {
    return self == type(of: self).version4
  }
}

func == (firstModel: NSManagedObjectModel, otherModel: NSManagedObjectModel) -> Bool {
  return firstModel.entitiesByName == otherModel.entitiesByName
}
