/*
 * Copyright 2002, 2016 IBM Corp.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.  
 *
 *  Author: Sami Salkosuo, sami.salkosuo@fi.ibm.com
*/
package clenotes.commands

import clenotes.CLENotesSession
import clenotes.Command
import clenotes.Logger
import java.util.Calendar
import java.util.Date
import lotus.domino.DateTime
import lotus.domino.DocumentCollection

class Appointments {

	def static execute(Command cmd) {

		var mailDb = CLENotesSession::getMailDatabase()

		var printRequired = cmd.hasOption("required")
		var printOptional = cmd.hasOption("optional")
		var printDesc = cmd.hasOption("desc")

		var notesSession = CLENotesSession.getSession

		var DateTime currentDateTime = notesSession.createDateTime("Today")

		currentDateTime.setNow()

		var searchAppointmentString = "Form = \"Appointment\""
		var DocumentCollection docCollection = null

		if (cmd.hasOption("sincedate")) {
			var String dateString = cmd.getOptionValue("sincedate")
			var dateStr = dateString.split('/');
			var calendarDateTime = Calendar.getInstance()

			calendarDateTime.set(Integer.parseInt(dateStr.get(2)), Integer.parseInt(dateStr.get(1)) - 1,
				Integer.parseInt(dateStr.get(0)), 0, 0, 1)

			var cutOffDate = notesSession.createDateTime(calendarDateTime)
			searchAppointmentString = "Form = \"Appointment\" & StartDateTime >= @Date( " + dateStr.get(2) + " ;" +
				dateStr.get(1) + "; " + dateStr.get(0) + ") "
			docCollection = mailDb.search(searchAppointmentString)
			var doc = docCollection.getFirstDocument();
			var index1 = 1
			while (doc != null) {
				var appointmentType = doc.getItemValue("AppointmentType")
				var appointmentFrom = doc.getItemValueString("From")
				var location = doc.getItemValueString("Location")
				var room = doc.getItemValueString("Room")

				//var startDateTime=doc.getItemValue("StartDateTime")
				//var endDateTime=doc.getItemValue("EndDateTime")
				var startDateTimeList = doc.getItemValue("StartDateTime")
				var endDateTimeList = doc.getItemValue("EndDateTime")

				var subject = doc.getItemValueString("Subject")
				var index = 0
				for (_startDateTime : startDateTimeList) {
					var DateTime startDateTime = _startDateTime as DateTime

					//print startDateTime,cutOffDate
					if (startDateTime.timeDifference(cutOffDate) < 0) {

						index = index + 1

					} else {

						var endDateTime = endDateTimeList.get(index) as DateTime

						//currentDateTime=session.createDateTime(Date())
						println("[" + index1 + "] " + subject)
						println("  From    : " + appointmentFrom)
						if (printRequired) {
							var requiredList = doc.getItemValue("AltRequiredNames")
							var names = ""
							for (n : requiredList) {
								names = names + n + ","

							}
							println("  Required: " + names.substring(0, names.length - 1))

						}
						if (printOptional) {
							var optionalList = doc.getItemValue("AltOptionalNames")
							var names = ""
							for (n : optionalList) {
								names = names + n + ","

							}
							println("  Optional: " + names.substring(0, names.length - 1))
						}
						var String desc = null
						if (printDesc) {
							desc = doc.getItemValueString("Body")
						}
						var filling = ""
						if (printDesc) {
							filling = "   "
						}

						//print required and optional list of name         
						println("  Start   " + filling + ": " + startDateTime)
						println("  End     " + filling + ": " + endDateTime)
						println("  Location" + filling + ": " + location)
						println("  Room    " + filling + ": " + room)
						if (printDesc) {
							println("  Description: " + desc)

						}
						index1 = index1 + 1
						index = index + 1
					}

				}
				doc = docCollection.getNextDocument()
			}

			return
		} else {
			docCollection = mailDb.search(searchAppointmentString)

		}

		var matches = docCollection.getCount()

		var weekDates = newArrayList
		if (cmd.hasOption("week")) {
			weekDates.add(currentDateTime.getDateOnly())
			for (i : ( 0 .. 6)) {
				var newDateTime = notesSession.createDateTime("Today")
				newDateTime.setNow()
				newDateTime.adjustDay(i + 1)
				weekDates.add(newDateTime.getDateOnly())

			}

		}

		var doc = docCollection.getLastDocument();
		var index1 = 1
		while (doc != null) {

			var appointmentType = doc.getItemValue("AppointmentType")
			var appointmentFrom = doc.getItemValueString("From")
			var location = doc.getItemValueString("Location")
			var room = doc.getItemValueString("Room")
			var startDateTimeList = doc.getItemValue("StartDateTime")
			var endDateTimeList = doc.getItemValue("EndDateTime")
			var index = 0
			for (_start : startDateTimeList) {
				var DateTime start = _start as DateTime
				var difference = currentDateTime.timeDifference(start)
				if (cmd.hasOption("today")) {
					var dateText1 = currentDateTime.getDateOnly()
					var dateText2 = start.getDateOnly()
					Logger::log("today option in appointments: " + dateText1 + " " + dateText2)
					if (dateText1 == dateText2) {
						difference = -1

					} else {
						difference = 1

					}

				}

				if (cmd.hasOption("week")) {

					var dateText1 = start.getDateOnly()
					if (weekDates.contains(dateText1)) {
						difference = -1

					} else {
						difference = 1

					}
				}

				if (cmd.hasOption("sincedate") || difference < 0) {

					var end = endDateTimeList.get(index)
					var subject = doc.getItemValueString("Subject")
					var _currentDateTime = notesSession.createDateTime(new Date())
					println("[" + index1 + "] " + subject)
					println("  From    : " + appointmentFrom)
					if (printRequired) {

						var requiredList = doc.getItemValue("AltRequiredNames")
						var names = ""
						for (n : requiredList) {
							names = names + n + ","

						}
						println("  Required: " + names.substring(0, names.length - 1))
					}
					if (printOptional) {
						var optionalList = doc.getItemValue("AltOptionalNames")
						var names = ""
						for (n : optionalList) {
							names = names + n + ","

						}
						println("  Optional: " + names.substring(0, names.length - 1))

					}
					var String desc = null
					if (printDesc) {
						desc = doc.getItemValueString("Body")
					}
					var filling = ""
					if (printDesc) {
						filling = "   "
					}

					//print required and optional list of name         
					println("  Start   " + filling + ": " + start)
					println("  End     " + filling + ": " + end)
					println("  Location" + filling + ": " + location)
					println("  Room    " + filling + ": " + room)
					if (printDesc) {
						println("  Description: " + desc)

					}

					index1 = index1 + 1
				}
				index = index + 1
			}
			doc = docCollection.getPrevDocument()
		}

		return
	}
}
