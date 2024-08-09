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
  Map<int, bool> _filtered = {};
  UnmodifiableMapView<int, bool> get filtered => UnmodifiableMapView(_filtered);

  void add(int tagID, String name) {
    _tags.add(Tag(tagID: tagID, name: name));
    _filtered[tagID] = false;
    notifyListeners();
  }

  void updateFilteredValue(int tagID, bool value) {
    _filtered[tagID] = value;
    notifyListeners();
  }

  void updateFilter(Map<int, bool> newFilter) {
    _filtered = newFilter;
    notifyListeners();
  }

  void resetFilter() {
    for (int i in _filtered.keys) {
      _filtered[i] = false;
    }
    notifyListeners();
  }

  Future<void> update(int userID) async {
    var response = await http.get(
      Uri.parse('https://szhp6s7oqx7vr6aspphi6ugyh40fhkne.lambda-url.eu-north-1.on.aws/get_tag?user_id=$userID'),
    );
    List responseList = jsonDecode(response.body)["data"];
    _tags.clear();
    for (int i = 0; i < responseList.length; ++i) {
      _tags.add(Tag(tagID: responseList[i][0], name: responseList[i][1]));
      if (!_filtered.containsKey(responseList[i][0])) {
        _filtered[responseList[i][0]] = false;
      }
    }
    notifyListeners();
  }
}