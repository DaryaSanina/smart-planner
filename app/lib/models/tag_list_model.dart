import 'dart:collection';

import 'package:app/server_interactions.dart';
import 'package:flutter/material.dart';

// This class represents a tag that can be assigned to a task
class Tag {
  const Tag({required this.tagID, required this.name});
  final int tagID;
  final String name;
}

// This model represents the list of tags created by the user
class TagListModel extends ChangeNotifier {
  // [tags] is the list of tags
  final List<Tag> _tags = [];
  UnmodifiableListView<Tag> get tags => UnmodifiableListView(_tags);

  // [filtered] is a dictionary where the ID of each tag is mapped onto
  // a boolean that represents whether to show tasks with this tag on the
  // dashboard
  final Map<int, bool> _filtered = {};
  UnmodifiableMapView<int, bool> get filtered => UnmodifiableMapView(_filtered);

  // This method adds a new tag with ID [tagID] and name [name] to the list
  // and does not add it to the current filter
  void add(int tagID, String name) {
    _tags.add(Tag(tagID: tagID, name: name));
    _filtered[tagID] = false;
    notifyListeners();
  }

  // This method adds or removes the specified tag with ID tagID from
  // the current filter.
  // [value] is true if the tasks with this tag need to be shown on the
  // dashboard, and false otherwise
  void updateFilteredValue(int tagID, bool value) {
    _filtered[tagID] = value;
    notifyListeners();
  }

  // This method clears the current filter, setting all [filtered] values
  // to false
  void resetFilter() {
    for (int i in _filtered.keys) {
      _filtered[i] = false;
    }
    notifyListeners();
  }

  // This method fetches the user's tags from the database
  // and does not add any new tags to the current filter
  Future<void> update(int userID) async {
    List<dynamic> tagList = await getUserTags(userID);

    // Update the list of tags
    _tags.clear();
    for (int i = 0; i < tagList.length; ++i) {
      _tags.add(Tag(tagID: tagList[i][0], name: tagList[i][1]));

      // If this is a new tag, do not add it to the current filter
      if (!_filtered.containsKey(tagList[i][0])) {
        _filtered[tagList[i][0]] = false;
      }
    }

    notifyListeners();
  }
}