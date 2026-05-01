import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzl;

void initializeTimezone() {
  tz.initializeTimeZones();
  tzl.setLocalLocation(tzl.getLocation('Asia/Seoul'));
}
