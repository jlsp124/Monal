//
//  Created by Alex.M on 08.07.2022.
//

import SwiftUI

struct MessageTimeView: View {
    @Environment(\.chatTheme) var theme

    let text: String
    let userType: UserType
    let encrypted: Bool

    var body: some View {
        HStack(spacing: 4) {
            if encrypted {
                Image(systemName: "lock.fill")
            }
            Text(text)
        }
        .foregroundColor(theme.colors.messageTimeText(userType))
    }
}

struct MessageTimeWithCapsuleView: View {
    let text: String
    let isCurrentUser: Bool
    let encrypted: Bool

    var body: some View {
        HStack(spacing: 4) {
            if encrypted {
                Image(systemName: "lock.fill")
            }
            Text(text)
        }
        .foregroundColor(.white)
        .opacity(0.8)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .padding(.horizontal, 8)
        .background {
            Capsule()
                .foregroundColor(.black.opacity(0.4))
        }
    }
}

