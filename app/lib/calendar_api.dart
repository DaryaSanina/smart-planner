import 'package:googleapis/calendar/v3.dart';

class CalendarClient {
  // For storing the CalendarApi object, this can be used
  // for performing all the operations

  static CalendarApi? calendar;

  Future<Events> get() async {
    String calendarID = "primary";
    Events events = (await calendar?.events.list(calendarID))!;
    return events;
  }
}