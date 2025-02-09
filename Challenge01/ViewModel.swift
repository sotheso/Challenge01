//
//  ViewModel.swift
//  SearchObservableCombine
//
//  Created by Alfian Losari on 03/08/24.
//

import Combine
// برای مدیریت تغییرات داده
import Observation
import Foundation

@MainActor
@Observable class ViewModel {
    
    let api = API()
    
// وضعیت لودینگ یا ارور یا ... = .idle
    var state = ViewState<[String]>.idle
// برای ذخیره و کنترل تسک که خروجی نداره
    var searchTask: Task<Void, Never>?

// مدیریت سرچ با Combine
    // @ObservationIgnored دقیقا برعکس @Observable
    // تغییرات توی سرچ بار رو به طور خودکار دنبال نمیکنه
    @ObservationIgnored var searchTextSubject = CurrentValueSubject<String, Never>("")
    @ObservationIgnored var cancellables: Set<AnyCancellable> = []
    
    // اینجا بهش مقدار اولیه دادیم یا تعییرات رو دستی بهش بگیم انجام بده بجای خودکار
    init() {
        // وقتی کاربر متن جستجو را پاک کند، باید صفحه به حالت اولیه برگرده
        searchTextSubject
            .filter { $0.isEmpty }
            .sink { [weak self] _ in
                guard let self else { return }
                self.searchTask?.cancel()
                self.displayIdleState()
            }.store(in: &cancellables)
            
        
        searchTextSubject
// صبر میکنه تا کاربر نوشتنش تموم بشه
        // بعد تماس با ای پی ای برقرار میکنه
        // https://rxmarbles.com/#debounce
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sink { [weak self] text in
                guard let self else { return }
                self.searchTask?.cancel()
                self.searchTask = createSearchTask(text)
            }
            .store(in: &cancellables)
    }
    
    // ارسال مقدار جدید
    var searchText = "" {
        didSet {
            searchTextSubject.send(searchText)
        }
    }
    
    var isSearchNotFound: Bool {
        let isDataEmpty = state.data?.isEmpty ?? false
        return isDataEmpty && searchText.count > 0
    }
    
    func displayIdleState() {
        state = .data(API.stubs)
    }
    
    // این متد یک تسک جدید برای جستجو ایجاد می‌کنه
    func createSearchTask(_ text: String) -> Task<Void, Never> {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.state = .loading
            do {
                let data = try await api.search(text: text)
                // بررسی می‌کنه که آیا عملیات لغو شده است یا نه
                try Task.checkCancellation()
                self.state = .data(data)
            } catch {
                if error is CancellationError {
                    print("Search is cancelled")
                }
            }
        }
    }
}

