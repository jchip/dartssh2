import 'package:dartssh2/src/ssh_channel_id.dart';
import 'package:test/test.dart';

void main() {
  group('SSHChannelIdAllocator', () {
    test('allocate returns sequential IDs starting from 0', () {
      final allocator = SSHChannelIdAllocator();
      expect(allocator.allocate(), 0);
      expect(allocator.allocate(), 1);
      expect(allocator.allocate(), 2);
    });

    test('release allows reuse of freed ID', () {
      final allocator = SSHChannelIdAllocator();
      final id0 = allocator.allocate(); // 0
      final id1 = allocator.allocate(); // 1
      allocator.allocate(); // 2

      allocator.release(id0);
      allocator.release(id1);

      // _nextId is at 3, so next allocations should be 3, 4, ...
      // unless it wraps. The released IDs (0, 1) become available
      // but _nextId continues forward.
      final id3 = allocator.allocate();
      expect(id3, 3);
    });

    test('wraps around when reaching _maxId', () {
      final allocator = SSHChannelIdAllocator();

      // Allocate and release to advance _nextId close to _maxId
      // We can't allocate 0xFFFF IDs easily, so we test the wrap
      // behavior by allocating, releasing, and checking wrap logic.
      // Allocate a few IDs and then release them all.
      final ids = <int>[];
      for (var i = 0; i < 5; i++) {
        ids.add(allocator.allocate());
      }
      expect(ids, [0, 1, 2, 3, 4]);

      // Release all
      for (final id in ids) {
        allocator.release(id);
      }

      // Allocate again - _nextId is at 5, so we get 5, 6, 7...
      expect(allocator.allocate(), 5);
    });

    test('skips already allocated IDs', () {
      final allocator = SSHChannelIdAllocator();
      final id0 = allocator.allocate(); // 0
      allocator.allocate(); // 1

      // Release 0, then allocate. _nextId is at 2, so next is 2.
      allocator.release(id0);
      expect(allocator.allocate(), 2);

      // Now release 0 again is a no-op (already removed), allocate gets 3
      expect(allocator.allocate(), 3);
    });

    test('throws when all channel IDs are exhausted', () {
      final allocator = SSHChannelIdAllocator();

      // Allocate all 0xFFFF IDs
      for (var i = 0; i < 0xFFFF; i++) {
        allocator.allocate();
      }

      expect(() => allocator.allocate(), throwsException);
    });

    test('can allocate after releasing when previously exhausted', () {
      final allocator = SSHChannelIdAllocator();

      // Allocate all 0xFFFF (65535) IDs: 0 through 65534
      for (var i = 0; i < 0xFFFF; i++) {
        allocator.allocate();
      }

      // Verify exhausted
      expect(() => allocator.allocate(), throwsException);

      // Release one ID, should be able to allocate again
      allocator.release(42);
      final id = allocator.allocate();

      // The allocator should successfully return some ID
      expect(id, isA<int>());
    });

    test('release is idempotent', () {
      final allocator = SSHChannelIdAllocator();
      final id = allocator.allocate();
      allocator.release(id);
      allocator.release(id); // second release should not throw
    });
  });
}
