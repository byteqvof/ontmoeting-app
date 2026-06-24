import 'package:flutter_test/flutter_test.dart';
import 'package:meetings_app/core/services/friendship_service.dart';

void main() {
  test('maps backend friendship statuses to UI actions', () {
    expect(FriendshipStatus.fromBackend('none').canRequest, isTrue);
    expect(FriendshipStatus.fromBackend('declined').canRequest, isTrue);
    expect(FriendshipStatus.fromBackend('pending_sent').isPendingSent, isTrue);
    expect(
      FriendshipStatus.fromBackend('pending_received').isPendingReceived,
      isTrue,
    );
    expect(FriendshipStatus.fromBackend('accepted').isFriend, isTrue);
    expect(FriendshipStatus.fromBackend('blocked').canRequest, isFalse);
  });

  test('counts only incoming pending friendship requests', () {
    final count = countIncomingFriendRequests([
      _friendship(
        profileId: 'profile-1',
        status: FriendshipStatus.pendingReceived,
        direction: 'incoming',
      ),
      _friendship(
        profileId: 'profile-2',
        status: FriendshipStatus.pendingSent,
        direction: 'outgoing',
      ),
      _friendship(
        profileId: 'profile-3',
        status: FriendshipStatus.accepted,
        direction: 'accepted',
      ),
    ]);

    expect(count, 1);
  });
}

FriendshipListItem _friendship({
  required String profileId,
  required FriendshipStatus status,
  required String direction,
}) {
  return FriendshipListItem(
    friendshipId: 'friendship-$profileId',
    profileId: profileId,
    status: status,
    direction: direction,
    updatedAt: DateTime(2026, 6, 20),
    profile: FriendProfile(
      id: profileId,
      displayName: 'Tester',
      initials: 'T',
    ),
  );
}
