//
//  NewsView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/7.
//

import SwiftUI

struct NewsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NewsCard(
                        title: "台積電宣布發放季度股利",
                        description: "台積電董事會通過每股配發2.75元股利",
                        date: "2025/02/07",
                        type: "股利發放"
                    )
                    
                    NewsCard(
                        title: "鴻海併購案獲准",
                        description: "鴻海集團併購案已獲得主管機關核准",
                        date: "2025/02/06",
                        type: "公司新聞"
                    )
                    
                    NewsCard(
                        title: "聯發科營收創新高",
                        description: "聯發科公布第四季營收，創下歷史新高",
                        date: "2025/02/05",
                        type: "財報公告"
                    )
                }
                .listRowBackground(Color.black)
                .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("最新資訊")
                        .navigationTitleStyle()
                }
            }
        }
        .padding(.top, 65)
    }
}

struct NewsCard: View {
    let title: String
    let description: String
    let date: String
    let type: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(type)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(4)
                
                Spacer()
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NewsView()
}
