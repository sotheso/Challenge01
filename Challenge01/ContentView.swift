//
//  ContentView.swift
//  Challenge01
//
//  Created by Sothesom on 21/11/1403.
//

import SwiftUI

@MainActor
struct ContentView: View {
    
    @State var vm = ViewModel()
    
    var body: some View {
        List(vm.state.data ?? [], id: \.self) {
            Text($0)
        }
// برای نمایش وضعیت سرچ
        .overlay {
            if vm.state.isLoading {
                ProgressView("Searching \"\(vm.searchText)\"")
            }
            
            if vm.isSearchNotFound {
                Text("Results not found for\n\"\(vm.searchText)\"")
                    .multilineTextAlignment(.center)
            }
        }
// نوار سرچ بالا
        .searchable(text: $vm.searchText, prompt: "Search")
        .navigationTitle("Observable X Combine Demo")
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
