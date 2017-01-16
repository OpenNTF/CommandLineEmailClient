package clenotes.utils.extensions

import clenotes.CLENotesSession
import clenotes.ErrorLogger
import clenotes.Logger
import java.util.HashMap
import java.util.Map
import lotus.domino.Database
import lotus.domino.DateTime
import lotus.domino.DocumentCollection
import lotus.domino.ViewEntry

class DatabaseExtensions {

	def static DocumentCollection findAllDocuments(Database db, int adjustDay) {

		return findDocuments(db, "@All", adjustDay)
	}

	def static DocumentCollection findMailDocuments(Database db, int adjustDay,String folderID) {

		var notesSession = CLENotesSession.getSession
		
		var formula="From!=\"" + notesSession.getUserName() + "\" & (Form=\"Memo\" | Form=\"Reply\")"
		if (folderID != null)
		{
			formula = formula + String.format('& @Contains(@Text($FolderRef);"%s")', folderID)
		}
		return findDocuments(db, formula, adjustDay)
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

	def static String getFolderID(Database db, String folderName) {

		var String folderID = null
		if (!db.getFolderReferencesEnabled()) {
			ErrorLogger::error(-106, "Folder references are not enabled. Can not search from folders.")
		} else {
			var folderMap = db.folders
			folderID = folderMap.get(folderName)
			if (folderID == null) {
				ErrorLogger::error(-107, "Folder '" + folderName + "' not found.")
			}
		}

		return folderID
	}

	/**
	 * Return a Map of folders where key is name and value is ID.
	 */
	def static Map<String, String> getFolders(Database db) {
		var folders = new HashMap<String, String>()

		var folderName = "$FolderAllInfo"

		var folderView = db.getView(folderName)
		if (folderView == null) {
			Logger::log("Folder view: " + folderName + " does not exist.")

		} else {
			var entries = folderView.allEntries
			var ViewEntry tmpEntry = null
			var entry = entries.firstEntry
			while (entry != null) {
				var values = entry.columnValues
				var _name = values.get(0) as String
				var _ID = values.get(1) as String
				folders.put(_name, _ID)

				tmpEntry = entries.nextEntry
				entry.recycle
				entry = tmpEntry
			}
		}

		return folders
	}
}
