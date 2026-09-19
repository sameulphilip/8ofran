import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/firebase/firebase_seed.dart';
import '../domain/priest.dart';

class PriestRepository {
  PriestRepository(this._items);
  final List<Priest> _items;

  List<Priest> all() => _items.where((p) => p.isAvailable).toList();

  List<Priest> directory() => List.unmodifiable(_items);

  Priest? byId(String id) {
    return _items.cast<Priest?>().firstWhere(
      (p) => p!.id == id,
      orElse: () => null,
    );
  }
}

final priestsStreamProvider = StreamProvider<List<Priest>>((ref) {
  final store = ref.watch(firestoreProvider);
  if (store == null) {
    return Stream.value(ref.watch(localDatabaseProvider).priests());
  }
  return store.collection('priests').snapshots().map((snapshot) {
    if (snapshot.docs.isEmpty) {
      seedFirestoreIfNeeded();
    }
    return [
      for (final doc in snapshot.docs)
        Priest.fromJson({'id': doc.id, ...doc.data()}),
    ];
  });
});

final priestsProvider = Provider<List<Priest>>((ref) {
  return ref.watch(priestsStreamProvider).value ?? const [];
});

final priestRepositoryProvider = Provider<PriestRepository>((ref) {
  return PriestRepository(ref.watch(priestsProvider));
});
