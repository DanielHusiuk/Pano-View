//
//  DateButton.swift
//  Pano View
//
//  Created by Daniel Husiuk on 29.10.2026.
//

import SwiftUI

struct DateButton: View {
    let formattedDate: String
    let formattedTime: String
    let isHorizontalLayout: Bool
    let isLandscape: Bool
    let isInterfaceHidden: Bool
    
    var body: some View {
        if #available(iOS 26.0, *) {
            Group {
                VStack(alignment: .center, content: {
                    Text(formattedDate)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(formattedTime)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                })
                .frame(minWidth: 80, maxWidth: 200, alignment: .center)
                .padding(.horizontal, -6)
                .padding(.vertical, 6)
                .glassEffect(.regular.interactive())
                .opacity(isInterfaceHidden ? 0.0 : 1.0)
                .disabled(isInterfaceHidden)
                .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
            }
            .padding(.top, isLandscape ? 10 : 0)
            
        } else {
            Button {
                
            } label: {
                VStack(alignment: .center, content: {
                    Text(formattedDate)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(formattedTime)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                })
                .padding(.horizontal, 10)
                .padding(.vertical, -0.5)
            }
            .allowsHitTesting(false)
            .buttonStyle(.borderedProminent)
            .tint(.clear)
            .foregroundStyle(.primary)
            .background(.ultraThinMaterial, in: Capsule())
            .clipShape(Capsule())
            .frame(minWidth: 80, maxWidth: 200, alignment: .center)
            .shadow(color: .black.opacity(0.2), radius: 5)
            .padding(.top, isHorizontalLayout ? 10 : 0)
            .padding(.top, isLandscape ? 10 : 0)
            .opacity(isInterfaceHidden ? 0.0 : 1.0)
            .disabled(isInterfaceHidden)
            .animation(.easeInOut(duration: 0.15), value: isInterfaceHidden)
        }
    }
}
