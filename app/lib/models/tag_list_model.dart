import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class Tag {
  const Tag({required this.tagID, required this.name});
  final int tagID;
  final String name;
}

class TagListModel extends ChangeNotifier {
  final List<Tag> _tags = [];
  UnmodifiableListView<Tag> get tags => UnmodifiableListView(_tags);
  final Map<int, bool> _filtered = {};
  UnmodifiableMapView<int, bool> get filtered => UnmodifiableMapView(_filtered);

  void add(int tagID, String name) {  // This procedure adds a new tag to the list and does not include it in the current filter
    _tags.add(Tag(tagID: tagID, name: name));
    _filtered[tagID] = false;
    notifyListeners();
  }

  void updateFilteredValue(int tagID, bool value) {  // This procedure adds or removes the specified tag from the current filter
    _filtered[tagID] = value;
    notifyListeners();
  }

  void resetFilter() {  // This procedure clears the current filter
    for (int i in _filtered.keys) {
      _filtered[i] = false;
    }
    notifyListeners();
  }

  Future<void> update(int userID) async {  // This procedure fetches the user's tags from the database and does not include any new tags in the current filter
    http.Response response = await http.get(
      Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_tag?user_id=$userID'),
    );
    List responseList = jsonDecode(response.body)["data"];

    // Update the list of tags
    _tags.clear();
    for (int i = 0; i < responseList.length; ++i) {
      _tags.add(Tag(tagID: responseList[i][0], name: responseList[i][1]));

      // If this is a new tag, do not include it in the current filter
      if (!_filtered.containsKey(responseList[i][0])) {
        _filtered[responseList[i][0]] = false;
      }
    }

    notifyListeners();
  }
}