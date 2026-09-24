import '../../features/admin/domain/church.dart';
import '../../features/priests/domain/priest.dart';
import '../constants/app_constants.dart';

const seedChurches = [
  Church(
    id: 'ch_cairo',
    name: 'كاتدرائية القديس مرقس الرسول',
    city: 'القاهرة',
    address: 'العباسية، القاهرة',
    mapsQuery: 'كاتدرائية القديس مرقس العباسية القاهرة',
  ),
  Church(
    id: 'ch_alex',
    name: 'الكاتدرائية المرقسية',
    city: 'الإسكندرية',
    address: 'الشاطبي، الإسكندرية',
    mapsQuery: 'الكاتدرائية المرقسية الشاطبي الإسكندرية',
  ),
  Church(
    id: 'ch_minya',
    name: 'كاتدرائية الشهيد مارجرجس',
    city: 'المنيا',
    address: 'كورنيش النيل، المنيا',
    mapsQuery: 'كاتدرائية مارجرجس المنيا',
  ),
  Church(
    id: 'ch_asyut',
    name: 'كاتدرائية رئيس الملائكة ميخائيل',
    city: 'أسيوط',
    address: 'أسيوط',
    mapsQuery: 'كاتدرائية الملاك ميخائيل أسيوط',
  ),
  Church(
    id: 'ch_tanta',
    name: 'كاتدرائية الشهيد مارجرجس',
    city: 'طنطا',
    address: 'طنطا، الغربية',
    mapsQuery: 'كاتدرائية مار جرجس طنطا',
  ),
];

const seedPriests = [
  Priest(
    id: 'p_youhanna',
    name: 'أبونا يوحنا',
    churchId: 'ch_cairo',
    churchName: 'كاتدرائية القديس مرقس الرسول',
    email: 'youhanna@ghofran.app',
  ),
  Priest(
    id: 'p_mina',
    name: 'أبونا مينا',
    churchId: 'ch_alex',
    churchName: 'الكاتدرائية المرقسية',
    email: 'mina@ghofran.app',
    firstSlotHour: 9,
    lastSlotHour: 12,
    offWeekdays: {DateTime.friday},
  ),
  Priest(
    id: 'p_dawoud',
    name: 'أبونا داود',
    churchId: 'ch_minya',
    churchName: 'كاتدرائية الشهيد مارجرجس',
    email: 'dawoud@ghofran.app',
    isAvailable: false,
  ),
  Priest(
    id: 'p_kirollos',
    name: 'أبونا كيرلس',
    churchId: 'ch_asyut',
    churchName: 'كاتدرائية رئيس الملائكة ميخائيل',
    email: 'kirollos@ghofran.app',
  ),
  Priest(
    id: 'p_bishoy',
    name: 'أبونا بيشوي',
    churchId: 'ch_tanta',
    churchName: 'كاتدرائية الشهيد مارجرجس',
    email: 'bishoy@ghofran.app',
    firstSlotHour: 16,
    lastSlotHour: 20,
    slotMinutes: 45,
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
    if (church.name == query || church.city == query || church.id == query) {
      return church;
    }
  }
  return null;
}
