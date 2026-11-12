//
//  Created by Alex.M on 07.07.2022.
//

import SwiftUI

struct AvatarImageView: View {

    let user: User?
    let avatarSize: CGFloat
    var avatarCacheKey: String? = nil

    var body: some View {
        if let user = user, let avatarImage = user.avatarImage {
            Image(uiImage: avatarImage)
                .resizable()
                .scaledToFill()
                .viewSize(avatarSize)
                .clipShape(Circle())
        } else {
            AsyncImage(url: user?.avatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray)
            }
            .viewSize(avatarSize)
            .clipShape(Circle())
        }
    }
}

struct AvatarImageView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarImageView(
            user: User(id: UUID().uuidString, name: "Dummy User", avatarURL:URL(string: "https://placeimg.com/640/480/sepia"), isCurrentUser:false),
            avatarSize: 32
        )
    }
}
