//
//  RealmRepository.swift
//  PickPle
//
//  Created by 정인선 on 7/21/25.
//

import Foundation
import RealmSwift

protocol RealmRepository {
    func getFileURL()
    func readTable<T: Object>(type: T.Type) -> Results<T>
    func addItem<T: Object>(type: T.Type, item: T)
    func deleteItem<T: Object>(type: T.Type, item: T)
}

final class DefaultRealmRepository: RealmRepository {
    private var realm: Realm { try! Realm() }
    
    func getFileURL() {
        guard let fileURL = realm.configuration.fileURL else { return }
        print("📁", fileURL)
    }
        
    func readTable<T: Object>(type: T.Type) -> Results<T> {
        return realm.objects(type)
    }
    
    func addItem<T: Object>(type: T.Type, item: T) {
        do {
            try realm.write {
                realm.add(item, update: .modified)
                print("realm add")
            }
        } catch {
            print(error)
        }
    }
    
    func deleteItem<T: Object>(type: T.Type, item: T) {
        do {
            try realm.write {
                realm.delete(item)
                print("realm delete")
            }
        } catch {
            print(error)
        }
    }
}
