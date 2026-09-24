import '../models/event_access_model.dart';

/// DevSpace lists hackathons in India only. Devpost is a global feed with no
/// country data, so its events can't be verified as India-based. The sync no
/// longer imports them, but rows synced earlier may still be in the events
/// table until the sync's cleanup removes them — hide those in the meantime.
bool isNonIndianHackathon(EventAccessModel event) {
  if (event.type.toLowerCase() != 'hackathon') return false;
  final host = Uri.tryParse(event.link)?.host.toLowerCase() ?? '';
  return host == 'devpost.com' || host.endsWith('.devpost.com');
}
