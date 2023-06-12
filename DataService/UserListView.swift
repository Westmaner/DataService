//
//  UserListView.swift
//  DataService
//
//  Created by Tim Yoon on 6/11/23.
//
//  SwiftUI
//  Decouple peristence (DataService) from ViewModel
//  Combine framework and Dependency Injection
//  MVVM Example
//
//  MockDataService and UserDefaultDataService
//  Could be easily extended to Firebase Firestore or CoreData


import SwiftUI
import Combine


// Model
struct User: Identifiable, Codable {
    var id = UUID()
    var name = ""
}


// ViewModel
class UsersViewModel: ObservableObject {
    @Published private(set) var users: [User] = []
    
    private let ds: any DataService
    private var cancellables = Set<AnyCancellable>()
    
    init(ds: any DataService = MockDataService()) {
        self.ds = ds
        ds.get()
            .sink { error in
                fatalError("\(error)")
            } receiveValue: { users in
                self.users = users
            }
            .store(in: &cancellables)
    }
    
    func add(user: User) {
        ds.add(user)
    }
    func update(user: User) {
        ds.update(user)
    }
    func delete(indexSet: IndexSet) {
        ds.delete(indexSet: indexSet)
    }
}

struct UserEditView: View {
    @State var user: User
    var save: (User)->()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            TextField("Username", text: $user.name)
                .textFieldStyle(.roundedBorder)
            Button {
                save(user)
                dismiss()
            } label: {
                Text("Save")
            }

        }
        .padding()
    }
}

struct UserListView: View {
    @ObservedObject var vm: UsersViewModel
    @State private var isShowingSheet = false
    
    var body: some View {
        NavigationStack {
            List{
                ForEach(vm.users){ user in
                    NavigationLink {
                        UserEditView(user: user) { returnedUser in
                            vm.update(user: returnedUser)
                        }
                    } label: {
                        Text("\(user.name)")
                    }
                }
                .onDelete(perform: vm.delete)
            }
            .navigationTitle("Users")
            .toolbar {
                Button {
                    isShowingSheet = true
                } label: {
                    Text("Add")
                }

            }
            .sheet(isPresented: $isShowingSheet) {
                NavigationStack {
                    UserEditView(user: User()) { returnedUser in
                        vm.add(user: returnedUser)
                    }
                    .navigationTitle("Add User")
                }
            }
        }
    }
}

struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        UserListView(vm: UsersViewModel(ds: CoreDataDataService(manager: PersistenceController.preview)))
    }
}

protocol DataService: ObservableObject {
    func get() -> AnyPublisher<[User], Error>
    func add(_ user: User)
    func update(_ user: User)
    func delete(indexSet: IndexSet)
}

class MockDataService: DataService {
    @Published private var users: [User] = []
    
    func get() -> AnyPublisher<[User], Error> {
        $users.tryMap({$0}).eraseToAnyPublisher()
    }
    
    func add(_ user: User) {
        users.append(user)
    }
    
    func update(_ user: User) {
        guard let index = users.firstIndex(where: {$0.id == user.id}) else { return }
        users[index] = user
    }
    
    func delete(indexSet: IndexSet) {
        users.remove(atOffsets: indexSet)
    }
}

class UserDefaultDataService: DataService {
    @Published private var users: [User] {
        didSet {
            save(items: users, key: key)
        }
    }
    
    private var key = "UserDefaultDataService"
    init(){
        users = []
        users = load(key: key)
    }
    func get() -> AnyPublisher<[User], Error> {
        $users.tryMap({$0}).eraseToAnyPublisher()
    }
    
    func add(_ item: User) {
        users.append(item)
    }
    
    func update(_ item: User) {
        guard let index = users.firstIndex(where: {$0.id == item.id}) else { return }
        users[index] = item
    }
    
    func delete(indexSet: IndexSet) {
        users.remove(atOffsets: indexSet)
    }
    
    // MARK: Private
    func save<T: Identifiable & Codable> (items: [T], key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode (items) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: key)
        }
    }
    func load<T: Identifiable & Codable> (key: String) -> [T] {
        guard let data = UserDefaults.standard.object (forKey: key) as? Data else {return [] }
        let decoder = JSONDecoder()
        if let dataArray = try? decoder.decode ([T].self, from: data) {
            return dataArray
        }
        return []
    }
    
}


