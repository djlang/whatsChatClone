//
//  PhoneContactManager.swift
//  WhatsChatClone
//
//  Created by dj on 2026/5/26.
//

import Foundation
import Contacts
import Combine

/// 原生手机联系人模型
struct PhoneContact: Identifiable {
    let id = UUID()
    let name: String
    let phoneNumber: String
}

final class PhoneContactManager: ObservableObject {
    @Published var contacts: [PhoneContact] = []
    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    
    private let contactStore = CNContactStore()
    
    /// 异步请求权限并抓取真机通讯录
    func fetchContacts() {
        // 1. 检查权限
        let status = CNContactStore.authorizationStatus(for: .contacts)
        DispatchQueue.main.async { self.authorizationStatus = status }
        
        switch status {
        case .authorized:
            loadContactsFromSystem()
        case .notDetermined:
            // 首次申请权限
            contactStore.requestAccess(for: .contacts) { [weak self] granted, _ in
                if granted {
                    self?.loadContactsFromSystem()
                }
            }
        default:
            print("❌ 用户拒绝了通讯录权限，可以在设置中手动开启")
        }
    }
    
    private func loadContactsFromSystem() {
        // 在后台线程拉取，防止卡死 UI
        DispatchQueue.global(qos: .userInitiated).async {
            var fetched: [PhoneContact] = []
            
            // 2. 指定我们要抓取的字段：姓、名、电话号码
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            do {
                try self.contactStore.enumerateContacts(with: request) { contact, _ in
                    // 3. 拼接姓名
                    let fullName = "\(contact.familyName)\(contact.givenName)".isEmpty ? "未知联系人" : "\(contact.familyName)\(contact.givenName)"
                    
                    // 4. 提取第一个电话号码
                    if let firstPhone = contact.phoneNumbers.first?.value.stringValue {
                        // 清洗一下号码中的空格或横杠
                        let cleanPhone = firstPhone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                        let phoneContact = PhoneContact(name: fullName, phoneNumber: cleanPhone)
                        fetched.append(phoneContact)
                    }
                }
                
                // 5. 按姓名拼音排序，并切回主线程刷新 UI
                DispatchQueue.main.async {
                    self.contacts = fetched.sorted { $0.name < $1.name }
                }
                
            } catch {
                print("❌ 遍历通讯录失败: \(error)")
            }
        }
    }
}
