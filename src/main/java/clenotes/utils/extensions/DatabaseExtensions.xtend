package clenotes.utils.extensions

import clenotes.CLENotesSession
import lotus.domino.Database
import lotus.domino.DateTime
import lotus.domino.DocumentCollection

class DatabaseExtensions {

	def static DocumentCollection findAllDocuments(Database db, int adjustDay) {

		return findDocuments(db, "@All", adjustDay)
	}

	def static DocumentCollection findMailDocuments(Database db, int adjustDay) {

		var notesSession = CLENotesSession.getSession
		return findDocuments(db, "From!=\"" + notesSession.getUserName() + "\" & (Form=\"Memo\" | Form=\"Reply\")",
			adjustDay)
	}

	def static DocumentCollection findDocuments(Database db, String searchString, int adjustDay) {

		var notesSession = CLENotesSession.getSession

		var DateTime dt = null
		if (adjustDay > -1) {
			dt = notesSession.createDateTime("Yesterday")
		}

		if (adjustDay > 0) {
			dt.adjustDay(-adjustDay)
		}

		var DocumentCollection docCollection
		docCollection = db.search(searchString, dt)

		docCollection

	}

}
