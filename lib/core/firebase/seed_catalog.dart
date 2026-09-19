import '../../features/admin/domain/church.dart';
import '../../features/priests/domain/priest.dart';
import '../constants/app_constants.dart';

const seedChurches = [
  Church(id: 'ch_cairo', name: 'القاهرة', city: 'القاهرة'),
  Church(id: 'ch_alex', name: 'الإسكندرية', city: 'الإسكندرية'),
  Church(id: 'ch_minya', name: 'المنيا', city: 'المنيا'),
  Church(id: 'ch_asyut', name: 'أسيوط', city: 'أسيوط'),
  Church(id: 'ch_tanta', name: 'طنطا', city: 'طنطا'),
];

const seedPriests = [
  Priest(
    id: 'p_youhanna',
    name: 'أبونا يوحنا',
    churchId: 'ch_cairo',
    churchName: 'القاهرة',
    email: 'youhanna@ghofran.app',
  ),
  Priest(
    id: 'p_mina',
    name: 'أبونا مينا',
    churchId: 'ch_alex',
    churchName: 'الإسكندرية',
    email: 'mina@ghofran.app',
  ),
  Priest(
    id: 'p_dawoud',
    name: 'أبونا داود',
    churchId: 'ch_minya',
    churchName: 'المنيا',
    email: 'dawoud@ghofran.app',
  ),
  Priest(
    id: 'p_kirollos',
    name: 'أبونا كيرلس',
    churchId: 'ch_asyut',
    churchName: 'أسيوط',
    email: 'kirollos@ghofran.app',
  ),
  Priest(
    id: 'p_bishoy',
    name: 'أبونا بيشوي',
    churchId: 'ch_tanta',
    churchName: 'طنطا',
    email: 'bishoy@ghofran.app',
  ),
];

Priest? priestByEmail(String email) {
  final query = email.trim().toLowerCase();
  if (query.isEmpty) return null;
  for (final priest in seedPriests) {
    if (priest.email.toLowerCase() == query) return priest;
  }
  return null;
}

bool isSeedAdminEmail(String email) {
  return email.trim().toLowerCase() == AppConstants.adminEmail;
}

Church? churchByName(String name) {
  final query = name.trim();
  if (query.isEmpty) return null;
  for (final church in seedChurches) {
    if (church.name == query || church.city == query) return church;
  }
  return null;
}
