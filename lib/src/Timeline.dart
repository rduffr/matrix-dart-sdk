/*
 * Copyright (c) 2019 Zender & Kurtz GbR.
 *
 * Authors:
 *   Christian Pauly <krille@famedly.com>
 *   Marcel Radzio <mtrnord@famedly.com>
 *
 * This file is part of famedlysdk.
 *
 * famedlysdk is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * famedlysdk is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with famedlysdk.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'Event.dart';
import 'Room.dart';
import 'User.dart';
import 'sync/EventUpdate.dart';

/// Represents the timeline of a room. The callbacks [onUpdate], [onDelete],
/// [onInsert] and [onResort] will be triggered automatically. The initial
/// event list will be retreived when created by the [room.getTimeline] method.
class Timeline {
  final Room room;
  List<Event> events = [];

  final onTimelineUpdateCallback onUpdate;
  final onTimelineInsertCallback onInsert;

  StreamSubscription<EventUpdate> sub;

  Timeline({this.room, this.events, this.onUpdate, this.onInsert}) {
    sub ??= room.client.connection.onEvent.stream.listen(_handleEventUpdate);
  }

  int _findEvent({String event_id, String txid, String unsigned_txid}) {
    int i;
    for (i = 0; i < events.length; i++) {
      if (events[i].content.containsKey("txid") &&
              (txid != null && events[i].content["txid"] == txid) ||
          events[i].id == event_id ||
          (unsigned_txid != null && events[i].content["txid"] == unsigned_txid))
        break;
    }
    return i;
  }

  void _handleEventUpdate(EventUpdate eventUpdate) async {
    try {
      if (eventUpdate.roomID != room.id) return;
      if (eventUpdate.type == "timeline" || eventUpdate.type == "history") {
        if (eventUpdate.content["status"] == -2) {
          int i = _findEvent(event_id: eventUpdate.content["event_id"]);
          if (i < events.length) events.removeAt(i);
        }
        // Is this event already in the timeline?
        else if (eventUpdate.content["status"] == 1 ||
            eventUpdate.content["status"] == -1 ||
            (eventUpdate.content.containsKey("unsigned") &&
                eventUpdate.content["unsigned"]["transaction_id"] is String)) {
          int i = _findEvent(
              event_id: eventUpdate.content["event_id"],
              txid: eventUpdate.content["content"]["txid"],
              unsigned_txid: eventUpdate.content.containsKey("unsigned")
                  ? eventUpdate.content["unsigned"]["transaction_id"]
                  : null);

          if (i < events.length) {
            events[i] = Event.fromJson(eventUpdate.content, room);
          }
        } else {
          User user = await room.client.store
              ?.getUser(matrixID: eventUpdate.content["sender"], room: room);
          if (user != null) {
            eventUpdate.content["displayname"] = user.displayName;
            eventUpdate.content["avatar_url"] = user.avatarUrl.mxc;
          }

          Event newEvent = Event.fromJson(eventUpdate.content, room);

          events.insert(0, newEvent);
          if (onInsert != null) onInsert(0);
        }
      }
      sortAndUpdate();
    } catch (e) {
      print("[WARNING] (_handleEventUpdate) ${e.toString()}");
    }
  }

  sortAndUpdate() {
    events
        ?.sort((a, b) => b.time.toTimeStamp().compareTo(a.time.toTimeStamp()));
    if (onUpdate != null) onUpdate();
  }
}

typedef onTimelineUpdateCallback = void Function();
typedef onTimelineInsertCallback = void Function(int insertID);