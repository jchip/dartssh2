import 'dart:async';

import 'package:dartssh2/src/utils/async_queue.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncQueue', () {
    late AsyncQueue<int> queue;

    setUp(() {
      queue = AsyncQueue<int>();
    });

    test('returns value synchronously when data is already queued', () {
      queue.add(1);
      final result = queue.next;
      expect(result, isA<int>());
      expect(result, equals(1));
    });

    test('returns a Future when no data is queued', () {
      final result = queue.next;
      expect(result, isA<Future<int>>());
    });

    test('future completes when data is added after calling next', () async {
      final future = queue.next as Future<int>;
      queue.add(42);
      expect(await future, equals(42));
    });

    test('multiple items are returned in FIFO order', () {
      queue.add(1);
      queue.add(2);
      queue.add(3);
      expect(queue.next, equals(1));
      expect(queue.next, equals(2));
      expect(queue.next, equals(3));
    });

    test('multiple waiters are resolved in FIFO order', () async {
      final f1 = queue.next as Future<int>;
      final f2 = queue.next as Future<int>;
      final f3 = queue.next as Future<int>;

      queue.add(10);
      queue.add(20);
      queue.add(30);

      expect(await f1, equals(10));
      expect(await f2, equals(20));
      expect(await f3, equals(30));
    });

    test('interleaved add and next', () async {
      queue.add(1);
      expect(queue.next, equals(1));

      final f = queue.next as Future<int>;
      queue.add(2);
      expect(await f, equals(2));

      queue.add(3);
      queue.add(4);
      expect(queue.next, equals(3));
      expect(queue.next, equals(4));
    });

    test('length returns number of waiting completers', () {
      expect(queue.length, equals(0));
      queue.next; // creates a waiter
      expect(queue.length, equals(1));
      queue.next; // creates another waiter
      expect(queue.length, equals(2));
    });

    test('length is 0 when data is queued but no waiters exist', () {
      queue.add(1);
      queue.add(2);
      expect(queue.length, equals(0));
    });

    test('hasWaiters is false when no consumers are waiting', () {
      expect(queue.hasWaiters, isFalse);
      queue.add(1);
      expect(queue.hasWaiters, isFalse);
    });

    test('hasWaiters is true when consumers are waiting', () {
      queue.next; // creates a waiter
      expect(queue.hasWaiters, isTrue);
    });

    test('hasWaiters becomes false after waiter is satisfied', () {
      queue.next; // creates a waiter
      expect(queue.hasWaiters, isTrue);
      queue.add(1); // satisfies the waiter
      expect(queue.hasWaiters, isFalse);
    });

    test('works with non-int types', () {
      final stringQueue = AsyncQueue<String>();
      stringQueue.add('hello');
      stringQueue.add('world');
      expect(stringQueue.next, equals('hello'));
      expect(stringQueue.next, equals('world'));
    });
  });
}
