import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/data/local_database.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../appointments/data/appointment_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../care/data/care_repository.dart';
import '../../care/domain/spiritual_canon.dart';
import '../../notifications/data/notification_repository.dart';
import '../domain/father_transfer.dart';
import 'priest_repository.dart';

class FatherTransferRepository {
  FatherTransferRepository(
    this._db,
    this._auth,
    this._care,
    this._appointments,
    this._notifications,
    this._priests, {
    FirebaseFirestore? store,
  }) : _store = store;

  final LocalDatabase _db;
  final AuthRepository _auth;
  final CareRepository _care;
  final AppointmentRepository _appointments;
  final NotificationRepository _notifications;
  final PriestRepository _priests;
  final FirebaseFirestore? _store;

  bool get _cloud => _store != null;

  Stream<List<FatherTransfer>> watchAll() {
    if (!_cloud) {
      return Stream.value(_sorted(_db.transfers()));
    }
    return _store!.collection('father_transfers').snapshots().map((snapshot) {
      return _sorted([for (final doc in snapshot.docs) _fromDoc(doc)]);
    });
  }

  Stream<List<FatherTransfer>> watchForUser(String userId) {
    if (!_cloud) {
      return Stream.value(
        _sorted([
          for (final item in _db.transfers())
            if (item.userId == userId) item,
        ]),
      );
    }
    return _store!
        .collection('father_transfers')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              _sorted([for (final doc in snapshot.docs) _fromDoc(doc)]),
        );
  }

  Stream<List<FatherTransfer>> watchForPriest(String priestId) {
    if (!_cloud) {
      return Stream.value(
        _sorted([
          for (final item in _db.transfers())
            if (item.fromPriestId == priestId || item.toPriestId == priestId)
              item,
        ]),
      );
    }
    final store = _store!;
    final fromQuery = store
        .collection('father_transfers')
        .where('fromPriestId', isEqualTo: priestId);
    final toQuery = store
        .collection('father_transfers')
        .where('toPriestId', isEqualTo: priestId);
    return Stream.multi((listener) {
      var from = <FatherTransfer>[];
      var to = <FatherTransfer>[];
      void emit() {
        final byId = <String, FatherTransfer>{
          for (final item in from) item.id: item,
          for (final item in to) item.id: item,
        };
        listener.add(_sorted(byId.values.toList()));
      }

      final first = fromQuery.snapshots().listen((snapshot) {
        from = [for (final doc in snapshot.docs) _fromDoc(doc)];
        emit();
      });
      final second = toQuery.snapshots().listen((snapshot) {
        to = [for (final doc in snapshot.docs) _fromDoc(doc)];
        emit();
      });
      listener.onCancel = () {
        first.cancel();
        second.cancel();
      };
    });
  }

  List<FatherTransfer> _sorted(List<FatherTransfer> items) {
    return [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  FatherTransfer _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final created = data['createdAt'];
    final iso = created is Timestamp
        ? created.toDate().toIso8601String()
        : (created as String? ?? DateTime.now().toIso8601String());
    return FatherTransfer.fromJson({...data, 'id': doc.id, 'createdAt': iso});
  }

  Future<FatherTransfer> request({
    required String userId,
    required String fromPriestId,
    required String toPriestId,
  }) async {
    if (fromPriestId.isEmpty || toPriestId.isEmpty || fromPriestId == toPriestId) {
      throw const TransferInvalidException();
    }
    final existing = await _pendingForUser(userId);
    if (existing != null) throw const TransferPendingException();

    final transfer = FatherTransfer(
      id: 'ft_${userId}_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      fromPriestId: fromPriestId,
      toPriestId: toPriestId,
      createdAt: DateTime.now(),
    );
    await _write(transfer);
    await _notifyPriests(transfer, requested: true);
    return transfer;
  }

  Future<FatherTransfer?> _pendingForUser(String userId) async {
    if (_cloud) {
      final snap = await _store!
          .collection('father_transfers')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in snap.docs) {
        final item = _fromDoc(doc);
        if (item.isPending) return item;
      }
      return null;
    }
    for (final item in _db.transfers()) {
      if (item.userId == userId && item.isPending) return item;
    }
    return null;
  }

  Future<void> cancel(String transferId) async {
    final transfer = await _byId(transferId);
    if (transfer == null || !transfer.isPending) return;
    await _write(transfer.copyWith(status: FatherTransferStatus.cancelled));
  }

  Future<FatherTransfer> respond({
    required String transferId,
    required String actorPriestId,
    required bool approve,
    bool asAdmin = false,
  }) async {
    final transfer = await _byId(transferId);
    if (transfer == null || !transfer.isPending) {
      throw const TransferInvalidException();
    }
    if (!approve) {
      final rejected = transfer.copyWith(status: FatherTransferStatus.rejected);
      await _write(rejected);
      await _notifications.add(
        userId: transfer.userId,
        title: AppStrings.changeFather,
        body: AppStrings.changeFatherRejected,
      );
      return rejected;
    }

    var next = transfer;
    if (asAdmin) {
      next = transfer.copyWith(fromApproved: true, toApproved: true);
    } else if (actorPriestId == transfer.fromPriestId) {
      next = transfer.copyWith(fromApproved: true);
    } else if (actorPriestId == transfer.toPriestId) {
      next = transfer.copyWith(toApproved: true);
    } else {
      throw const TransferInvalidException();
    }

    if (next.bothApproved) {
      next = next.copyWith(status: FatherTransferStatus.approved);
      await _write(next);
      await _apply(next);
      return next;
    }

    await _write(next);
    await _notifications.add(
      userId: transfer.userId,
      title: AppStrings.changeFather,
      body: AppStrings.transferWaitingOther,
    );
    return next;
  }

  Future<FatherTransfer?> _byId(String id) async {
    if (_cloud) {
      final snap = await _store!.collection('father_transfers').doc(id).get();
      if (!snap.exists) return null;
      return _fromDoc(snap);
    }
    for (final item in _db.transfers()) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _apply(FatherTransfer transfer) async {
    final nextPriest = _priests.byId(transfer.toPriestId);
    await _auth.writeFatherId(transfer.userId, transfer.toPriestId);
    await _care.reassign(
      userId: transfer.userId,
      priestId: transfer.toPriestId,
      priestUid: nextPriest?.uid,
    );
    await _appointments.cancelPendingFor(
      userId: transfer.userId,
      priestId: transfer.fromPriestId,
    );
    await _notifications.add(
      userId: transfer.userId,
      title: AppStrings.changeFather,
      body: AppStrings.changeFatherDone,
    );
    await _notifyPriests(transfer, requested: false);
  }

  Future<void> _notifyPriests(
    FatherTransfer transfer, {
    required bool requested,
  }) async {
    final title = requested
        ? AppStrings.fatherTransfers
        : AppStrings.changeFatherDone;
    final body = requested
        ? AppStrings.changeFatherPending
        : AppStrings.changeFatherDone;
    for (final priestId in {transfer.fromPriestId, transfer.toPriestId}) {
      final uid = _priests.byId(priestId)?.uid;
      if (uid == null || uid.isEmpty || uid == transfer.userId) continue;
      await _notifications.add(userId: uid, title: title, body: body);
    }
  }

  Future<void> _write(FatherTransfer transfer) async {
    if (_cloud) {
      await _store!.collection('father_transfers').doc(transfer.id).set({
        ...transfer.toJson(),
        'createdAt': Timestamp.fromDate(transfer.createdAt),
      });
      return;
    }
    await _db.saveTransfers([
      for (final item in _db.transfers())
        if (item.id != transfer.id) item,
      transfer,
    ]);
  }
}

final fatherTransferRepositoryProvider = Provider<FatherTransferRepository>((
  ref,
) {
  return FatherTransferRepository(
    ref.watch(localDatabaseProvider),
    ref.watch(authRepositoryProvider),
    ref.watch(careRepositoryProvider),
    ref.watch(appointmentRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
    ref.watch(priestRepositoryProvider),
    store: ref.watch(firestoreProvider),
  );
});

final fatherTransfersProvider = StreamProvider<List<FatherTransfer>>((ref) {
  final user = ref.watch(authControllerProvider);
  final repo = ref.watch(fatherTransferRepositoryProvider);
  if (user == null) return Stream.value(const <FatherTransfer>[]);
  if (user.isAdmin) return repo.watchAll();
  if (user.isPriest && user.priestId != null) {
    return repo.watchForPriest(user.priestId!);
  }
  return repo.watchForUser(user.id);
});

final myFatherTransferProvider = Provider<FatherTransfer?>((ref) {
  final user = ref.watch(authControllerProvider);
  if (user == null) return null;
  for (final item in ref.watch(fatherTransfersProvider).value ?? const []) {
    if (item.userId == user.id && item.isPending) return item;
  }
  return null;
});

final inboxTransfersProvider = Provider<List<FatherTransfer>>((ref) {
  final user = ref.watch(authControllerProvider);
  final items = ref.watch(fatherTransfersProvider).value ?? const [];
  if (user?.isAdmin ?? false) {
    return [for (final item in items) if (item.isPending) item];
  }
  final priestId = user?.priestId;
  if (priestId == null) return const [];
  return [
    for (final item in items)
      if (item.isPending &&
          (item.fromPriestId == priestId || item.toPriestId == priestId))
        item,
  ];
});

final flockCanonsProvider = StreamProvider<Map<String, SpiritualCanon>>((ref) {
  final user = ref.watch(authControllerProvider);
  final priestId = user?.priestId;
  if (priestId == null) {
    return Stream.value(const <String, SpiritualCanon>{});
  }
  return ref.watch(careRepositoryProvider).watchLatestCanons(priestId);
});
