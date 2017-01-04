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
import clenotes.CommandLineArguments
import clenotes.Logger
import lotus.domino.Database
import lotus.domino.DbDirectory
import clenotes.ErrorLogger

class Replicate {

	def static execute(Command cmd) {

		//replicateMailDb(session,config,opts,args)
		var DbDirectory dbDirectory
		var databaseFile = cmd.getOptionValue("database")
		var Database dominoDatabase
		
		var notesSession=CLENotesSession.getSession
		
		if (databaseFile.nullOrEmpty) {
			dominoDatabase = CLENotesSession::getMailDatabase()

		} else {
			dbDirectory = notesSession.getDbDirectory(null)
			dominoDatabase = CLENotesSession::openDatabase(dbDirectory, databaseFile, null)

		}
		Logger::log("Database to replicate: " + dominoDatabase.title)
		var server = cmd.getOptionValue("server")
		Logger::log("Server: " + server)
		if (server.nullOrEmpty) {
			server = dominoDatabase.getServer()
			println("Using replication server: " + server)

		}
		var replicaId = cmd.getOptionValue("replica-id")
		if (replicaId.nullOrEmpty) {
			replicaId = CommandLineArguments::getValue("replica-id")
		}
		if (replicaId.nullOrEmpty) {
			replicaId = dominoDatabase.getReplicaID()
			println("Using Replica ID: " + replicaId)

		}
		var dbFilePath = dominoDatabase.getFilePath()
		if (!server.startsWith("CN=")) {
			Logger::log("Changing server to canonical format: " + server + "...")
			server = notesSession.createName(server).canonical
			Logger::log("Changed server to canonical format: " + server)
		}

		Logger::log("Replicate " + dbFilePath + " with server: " + server)

		var isReplicaDone = dominoDatabase.replicate(server)
		if (isReplicaDone) {
			println("Database " + dominoDatabase.getTitle() + " replicated.")

		} else {
			ErrorLogger::error(-101,"Error occurred while replicating database.")

		}

	}
}
