//
//  DataServiceApp.swift
//  DataService
//
//  Created by Tim Yoon on 6/11/23.
//

import SwiftUI

@main
struct DataServiceApp: App {
    @StateObject var vm = UsersViewModel(ds: CoreDataDataService(manager: PersistenceController.shared))
    var body: some Scene {
        WindowGroup {
            UserListView(vm: vm)
        }
    }
}
