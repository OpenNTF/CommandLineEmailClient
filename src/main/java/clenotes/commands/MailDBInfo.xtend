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

class MailDBInfo {

	def static execute(Command cmd) {
		var mailDb = CLENotesSession::getMailDatabase()

		var notesSession=CLENotesSession.getSession
		
		println("Mail database information")

		println("User name     : " + notesSession.getUserName())
		println("Title         : " + mailDb.getTitle())
		println("Replica ID    : " + mailDb.getReplicaID())
		println("File path     : " + mailDb.getFilePath())
		println("Template      : " + mailDb.templateName)
		println("ODS version   : " + mailDb.getFileFormat())
		println("Server        : " + mailDb.getServer())
		var str = String::format("Size (used %%) : %.2f MB (%.2f%%)", ((mailDb.getSize()) / 1048576f),
			mailDb.getPercentUsed())
		println(str)
		println("Created       : " + mailDb.getCreated().getGMTTime())
		println("Modified      : " + mailDb.getLastModified().getGMTTime())
		println("HTTP URL      : " + mailDb.getHttpURL())
		println("Notes URL     : " + mailDb.getNotesURL())
	}

}
