import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';

class CalendarClient {
  // For storing the CalendarApi object, this can be used
  // for performing Google Calendar operations

  static CalendarApi? calendar;

  Future<Events> getEvents() async {
    // This function returns all events from the user's calendar
    String calendarID = "primary";
    Events events = (await calendar?.events.list(calendarID))!;
    return events;
  }

  Future<Event> getEvent(String eventID) async {
    // This function returns the details of the event with the specified ID, or null, if the event does not exist
    String calendarID = "primary";
    Event event = (await calendar?.events.get(calendarID, eventID))!;
    return event;
  }

  Future<String> add(String name, String description, DateTime startDate, TimeOfDay? startTime, DateTime endDate, TimeOfDay? endTime) async {
    // This procedure adds an event to the user's primary calendar and returns its ID

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

    EventDateTime eventEnd = EventDateTime();
    eventEnd.timeZone = DateTime.now().timeZoneName;
    if (endTime != null) {
      eventEnd.dateTime = DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);
    }
    else {
      eventEnd.date = DateTime(endDate.year, endDate.month, endDate.day);
    }
    event.end = eventEnd;

    event = (await calendar?.events.insert(event, calendarID))!;
    return event.id!;
  }

  Future<void> update(String eventID, String? name, String? description, DateTime? startDate, TimeOfDay? startTime, DateTime? endDate, TimeOfDay? endTime) async {
    // This procedure updates an event in the user's Google Calendar with the given parameters

    String calendarID = "primary";
    Event event = Event();

    event.summary = name;
    event.description = description;
    event.status = "confirmed";

    EventDateTime eventStart = EventDateTime();
    eventStart.timeZone = DateTime.now().timeZoneName;
    if (startDate != null) {
      if (startTime != null) {
        eventStart.dateTime = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
      }
      else {
        eventStart.date = DateTime(startDate.year, startDate.month, startDate.day);
      }
      event.start = eventStart;
    }

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

    try {
      await calendar?.events.update(event, calendarID, eventID);
    } on Exception {
      await calendar?.events.insert(event, calendarID);
    }
  }

  Future<void> delete(String eventID) async {
    // This procedure removes an event from the user's Google Calendar
    String calendarID = "primary";
    await calendar?.events.delete(calendarID, eventID);
  }
}