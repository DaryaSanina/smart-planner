import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';

// A class for storing the CalendarApi object, which can be used to perform
// Google Calendar operations
class CalendarClient {
  static CalendarApi? calendar;

  // This method returns all events from the user's calendar
  Future<Events> getEvents() async {
    String calendarID = "primary";
    Events events = (await calendar?.events.list(calendarID))!;
    return events;
  }

  // This method returns the details of the event with the specified [eventID],
  // or null, if the event does not exist
  Future<Event> getEvent(String eventID) async {
    String calendarID = "primary";
    Event event = (await calendar?.events.get(calendarID, eventID))!;
    return event;
  }

  // This method adds an event to the user's primary calendar and returns its ID
  // The parameters are the details of the event
  Future<String> add(
      String name,
      String description,
      DateTime startDate,
      TimeOfDay? startTime,
      DateTime endDate,
      TimeOfDay? endTime
  ) async {
    String calendarID = "primary";
    Event event = Event();

    event.summary = name;
    event.description = description;

    EventDateTime eventStart = EventDateTime();
    eventStart.timeZone = DateTime.now().timeZoneName;
    if (startTime != null) {
      eventStart.dateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startTime.hour,
        startTime.minute
      );
    }
    else {
      eventStart.date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day
      );
    }
    event.start = eventStart;

    EventDateTime eventEnd = EventDateTime();
    eventEnd.timeZone = DateTime.now().timeZoneName;
    if (endTime != null) {
      eventEnd.dateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        endTime.hour,
        endTime.minute
      );
    }
    else {
      eventEnd.date = DateTime(endDate.year, endDate.month, endDate.day);
    }
    event.end = eventEnd;

    event = (await calendar?.events.insert(event, calendarID))!;
    return event.id!;
  }

  // This method updates an event in the user's Google Calendar with the
  // given parameters
  Future<void> update(
      String eventID,
      String? name,
      String? description,
      DateTime? startDate,
      TimeOfDay? startTime,
      DateTime? endDate,
      TimeOfDay? endTime
) async {
    String calendarID = "primary";
    Event event = Event();

    event.summary = name;
    event.description = description;
    event.status = "confirmed";

    EventDateTime eventStart = EventDateTime();
    eventStart.timeZone = DateTime.now().timeZoneName;
    if (startDate != null) {
      if (startTime != null) {
        eventStart.dateTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          startTime.hour,
          startTime.minute
        );
      }
      else {
        eventStart.date = DateTime(
          startDate.year,
          startDate.month,
          startDate.day
        );
      }
      event.start = eventStart;
    }

    if (endDate != null) {
      EventDateTime eventEnd = EventDateTime();
      eventEnd.timeZone = DateTime.now().timeZoneName;
      if (endTime != null) {
        eventEnd.dateTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          endTime.hour,
          endTime.minute
        );
      }
      else {
        eventEnd.date = DateTime(endDate.year, endDate.month, endDate.day);
      }
      event.end = eventEnd;
    }

    try {
      await calendar?.events.update(event, calendarID, eventID);
    } on Exception {
      await calendar?.events.insert(event, calendarID);
    }
  }

  // This method removes the event with the specified [eventID] from the user's
  // Google Calendar
  Future<void> delete(String eventID) async {
    String calendarID = "primary";
    await calendar?.events.delete(calendarID, eventID);
  }
}