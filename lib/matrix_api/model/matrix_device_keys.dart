/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

class MatrixDeviceKeys {
  String userId;
  String deviceId;
  List<String> algorithms;
  Map<String, String> keys;
  Map<String, Map<String, String>> signatures;
  Map<String, dynamic> unsigned;
  String get deviceDisplayName =>
      unsigned != null ? unsigned['device_display_name'] : null;

  // This object is used for signing so we need the raw json too
  Map<String, dynamic> _json;

  MatrixDeviceKeys(
    this.userId,
    this.deviceId,
    this.algorithms,
    this.keys,
    this.signatures, {
    this.unsigned,
  });

  MatrixDeviceKeys.fromJson(Map<String, dynamic> json) {
    _json = json;
    userId = json['user_id'];
    deviceId = json['device_id'];
    algorithms = json['algorithms'].cast<String>();
    keys = Map<String, String>.from(json['keys']);
    signatures = Map<String, Map<String, String>>.from(
        (json['signatures'] as Map)
            .map((k, v) => MapEntry(k, Map<String, String>.from(v))));
    unsigned = json['unsigned'] != null
        ? Map<String, dynamic>.from(json['unsigned'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final data = _json ?? <String, dynamic>{};
    data['user_id'] = userId;
    data['device_id'] = deviceId;
    data['algorithms'] = algorithms;
    data['keys'] = keys;

    if (signatures != null) {
      data['signatures'] = signatures;
    }
    if (unsigned != null) {
      data['unsigned'] = unsigned;
    }
    return data;
  }
}
