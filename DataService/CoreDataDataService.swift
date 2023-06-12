//
//  CoreDataDataService.swift
//  DataService
//
//  Created by Tim Yoon on 6/11/23.
//

import Foundation
import CoreData
import Combine

extension User {
    init(entity: UserEntity) {
        id = entity.id
        name = entity.name
    }
}

class CoreDataDataService: DataService {
    @Published private var users: [UserEntity] = []
    
    private let manager: PersistenceController
    private let sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
    private let fetchRequest = NSFetchRequest<UserEntity>(entityName: "UserEntity")
    
    init(manager: PersistenceController = PersistenceController.preview) {
        self.manager = manager
        fetch()
    }
    
    // MARK: Public Funcs CRUD
    func get() -> AnyPublisher<[User], Error> {
        $users.tryMap { userEntities in
            userEntities.map { userEntity in
                User(entity: userEntity)
            }
        }
        .eraseToAnyPublisher()
    }
    
    func add(_ user: User) {
        let userEntity = UserEntity(context: manager.container.viewContext)
        userEntity.id = user.id
        userEntity.name = user.name
        userEntity.timestamp = Date.now
        save()
    }
    
    func update(_ user: User) {
        guard let index = users.firstIndex(where: {$0.id == user.id}) else { return }
        users[index].id = user.id
        users[index].name = user.name
        save()
    }
    
    func delete(indexSet: IndexSet) {
        for index in indexSet {
            manager.container.viewContext.delete(users[index])
        }
        save()
    }
    
    
    // MARK: private funcs
    private func fetch(){
        do {
            users = try manager.container.viewContext.fetch(fetchRequest)
        } catch let error {
            fatalError("Error: Unable to fetch coredata \(error.localizedDescription)")
        }
    }
    
    private func save() {
        do {
            try manager.container.viewContext.save()
        } catch let error {
            print("Error saving Core Data. \(error.localizedDescription)")
        }
        
        fetch()
    }
}
