/*
 * Copyright 2002, 2017 IBM Corp.
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
import lotus.domino.Database
import lotus.domino.View
import lotus.domino.ViewEntry

import static extension clenotes.utils.extensions.DatabaseExtensions.*

class Dev {

	def static execute(Command cmd) {

		println("Command for development/experimentation/misc.")
		println()
		// var notesSession = CLENotesSession.getSession
		var mailDb = CLENotesSession::getMailDatabase()

		if (cmd.hasOption("folderrefs")) {
			folderRefs(mailDb, cmd)
		}

	}

	private def static folderRefs(Database mailDb, Command cmd) {
		/*
		 * By default, Domino does not track in which folder document is.
		 * Folder references can be enabled. But existing documents are not tracked, only new ones
		 * http://www-01.ibm.com/support/docview.wss?uid=swg21209890 
		 * 
		 * See also:
		 * http://www-01.ibm.com/support/docview.wss?rs=475&uid=swg21201309
		 * http://www-01.ibm.com/support/docview.wss?rs=463&uid=swg21092899
		 * 
		 * Folder references need hidden views. View them using instructions here:
		 * http://www-01.ibm.com/support/docview.wss?uid=swg21091578
		 * 
		 */
		if (mailDb.getFolderReferencesEnabled()) {
			println("Folder references are ENABLED.")
		} else {
			println("Folder references are NOT enabled.")
		}

		if (cmd.hasOption("enable")) {
			mailDb.setFolderReferencesEnabled(true)
			println("Folder references are NOW ENABLED.")
		}
		if (cmd.hasOption("disable")) {
			mailDb.setFolderReferencesEnabled(false)
			println("Folder references are NOW DISABLED.")
		}

		if (cmd.hasOption("listfolders")) {
			var folderName = "$FolderAllInfo"
			var folderView = mailDb.getView(folderName)
			if (folderView == null) {
				println(folderName + " is NULL")
			} else {
				var entries = folderView.allEntries
				var ViewEntry tmpEntry = null
				var entry = entries.firstEntry
				while (entry != null) {
					var values = entry.columnValues
					for (value : values) {
						print(value)
						print(" ")
					}
					println()
					tmpEntry = entries.nextEntry
					entry.recycle
					entry = tmpEntry
				}
			}
			
			println()
			var folderMap=mailDb.folders
			println(folderMap)
			
		}

		if (cmd.hasOption("putallinfolder")) {
			for (_view : mailDb.views) {
				var view = _view as View
				if (view.isFolder) {
					var entryCollection=view.allEntries
					entryCollection.putAllInFolder(view.name)					
				}
			}
		}

	}
}
