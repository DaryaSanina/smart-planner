import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';

class CalendarClient {
  // For storing the CalendarApi object, this can be used
  // for performing all the operations

  static CalendarApi? calendar;

  Future<Events> get() async {
    // This function returns all events from the user's primary calendar
    String calendarID = "primary";
    Events events = (await calendar?.events.list(calendarID))!;
    return events;
  }

  Future<void> add(String name, String description, DateTime startDate, TimeOfDay? startTime, DateTime? endDate, TimeOfDay? endTime) async {
    // This procedure adds an event to the user's primary calendar
    String calendarID = "primary";
    Event event = Event();

    event.summary = name;
    event.description = description;

    EventDateTime eventStart = EventDateTime();
    eventStart.timeZone = DateTime.now().timeZoneName;
    if (startTime != null) {
      eventStart.dateTime = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
    }
    else {
      eventStart.date = DateTime(startDate.year, startDate.month, startDate.day);
    }
    event.start = eventStart;

    if (endDate != null) {
      EventDateTime eventEnd = EventDateTime();
      eventEnd.timeZone = DateTime.now().timeZoneName;
      if (endTime != null) {
        eventEnd.dateTime = DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);
      }
      else {
        eventEnd.date = DateTime(endDate.year, endDate.month, endDate.day);
      }
      event.end = eventEnd;
    }

    await calendar?.events.insert(event, calendarID);
  }
}