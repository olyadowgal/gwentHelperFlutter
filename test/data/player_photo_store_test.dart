import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/data/player_photo_store.dart';

void main() {
  late Directory documents;
  late File source;
  late PlayerPhotoStore store;

  setUp(() {
    documents = Directory.systemTemp.createTempSync('player_photo_store_test');
    addTearDown(() => documents.deleteSync(recursive: true));
    source = File('${documents.path}/cropped_source.jpg')
      ..writeAsBytesSync([1, 2, 3, 4, 5]);
    store = PlayerPhotoStore(documentsDirectory: () async => documents);
  });

  group('PlayerPhotoStore', () {
    group('`save`', () {
      test(
        '''
      Given a source image file
      When `save` is called
      Then it returns a `.jpg` file name without path separators
      And the stored copy has the same bytes as the source
      And the source file is left untouched
      ''',
        () async {
          // Given
          final sourceBytes = source.readAsBytesSync();

          // When
          final name = await store.save(source.path);

          // Then
          expect(name, endsWith('.jpg'));
          expect(name, isNot(contains('/')));
          expect(name, isNot(contains(r'\')));
          final stored = File('${documents.path}/player_photos/$name');
          expect(stored.existsSync(), isTrue);
          expect(stored.readAsBytesSync(), sourceBytes);
          expect(source.existsSync(), isTrue);
          expect(source.readAsBytesSync(), sourceBytes);
        },
      );

      test(
        '''
      Given the same source image
      When `save` is called twice
      Then the two returned names differ
      ''',
        () async {
          // Given / When
          final first = await store.save(source.path);
          final second = await store.save(source.path);

          // Then
          expect(first, isNot(second));
        },
      );
    });

    group('`resolve`', () {
      test(
        '''
      Given a saved photo
      When `resolve` is called with its name
      Then it returns the path inside `player_photos`
      ''',
        () async {
          // Given
          final name = await store.save(source.path);

          // When
          final path = await store.resolve(name);

          // Then
          expect(path, '${documents.path}/player_photos/$name');
        },
      );

      test(
        '''
      Given an unknown file name
      When `resolve` is called
      Then it returns null
      ''',
        () async {
          // Given / When
          final path = await store.resolve('missing.jpg');

          // Then
          expect(path, isNull);
        },
      );
    });

    group('`delete`', () {
      test(
        '''
      Given a saved photo
      When `delete` is called with its name
      Then the stored file is removed
      ''',
        () async {
          // Given
          final name = await store.save(source.path);
          final stored = File('${documents.path}/player_photos/$name');

          // When
          await store.delete(name);

          // Then
          expect(stored.existsSync(), isFalse);
        },
      );

      test(
        '''
      Given an unknown file name
      When `delete` is called
      Then it completes without throwing
      ''',
        () async {
          // Given / When
          final future = store.delete('missing.jpg');

          // Then
          await expectLater(future, completes);
        },
      );
    });
  });
}
