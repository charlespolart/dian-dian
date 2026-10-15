import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Reports product events to the server (`POST /api/events`): a counter
/// for what the data does not show otherwise, e.g. how often the free
/// tracker limit is hit. Fire-and-forget: never throws, never blocks.
class EventsService {
  final ApiService _api;

  EventsService({ApiService? api}) : _api = api ?? ApiService();

  Future<void> track(String name) async {
    try {
      final response = await _api.apiFetch('/api/events', method: 'POST', body: {'name': name});
      if (response.statusCode != 204) debugPrint('EventsService: $name → ${response.statusCode}');
    } catch (e) {
      debugPrint('EventsService: $name failed: $e');
    }
  }
}
