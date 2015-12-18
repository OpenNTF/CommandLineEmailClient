/*
 * Copyright 2002, 2015 IBM Corp.
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
package clenotes

import clenotes.utils.DxlUtils
import lotus.domino.Database
import lotus.domino.DbDirectory
import lotus.domino.NotesFactory
import lotus.domino.Session

class CLENotesSession {

	private static var Session session = null

	private static var Database mailDB = null

	/*
	 * Must be called during startup of CLENotes
	 */
	def static initSession(String serverHost, String password) {
		if (session == null) {
			if (password != null) {
				session = NotesFactory::createSession(serverHost, null as String, password)

			} else {
				session = NotesFactory::createSession()

			//notesSession = NotesFactory::createSessionWithFullAccess()
			}
		}
		session
	}

	/*
	 * Must be called during startup of CLENotes if using remote access
	 */
	def static initSession(String serverHost, String username, String password) {
		if (session == null) {

			session = NotesFactory::createSession(serverHost, username, password)
		}
		session
	}


	def static getSession() {
		return session
	}

	def static recycle() {
		session.recycle
	}

	def static Database getMailDatabase() {

		if (mailDB == null) {
			if (CommandLineArguments::hasOption("dxli")) {
				mailDB = DxlUtils.importDxl()
			} else {

				/*Return users mail database. Arguments are session that is used to
  get mail database and opts. If options has replica-id option, it is used
  to get local mail db replica*/
				var DbDirectory dbDirectory = null
				var serverName = CommandLineArguments::getValue("server-name")
				dbDirectory = session.getDbDirectory(serverName) //serverName may be null, opens default directory

				var replicaId = CommandLineArguments::getValue("replica-id")
				var databaseName = CommandLineArguments::getValue("database-name")

				mailDB = openDatabase(dbDirectory, databaseName, replicaId)
			}
		}
		mailDB

	}

	def static Database openDatabase(DbDirectory dbDirectory, String databaseName, String _replicaId) {

		var replicaId = _replicaId
		if (databaseName == null && replicaId == null) {

			if (CommandLineArguments::hasOption("local")) {
				var Database db = dbDirectory.openMailDatabase();
				replicaId = db.replicaID
				db.recycle
			} else {
				return dbDirectory.openMailDatabase()

			}
		}

		if (replicaId != null) {
			return dbDirectory.openDatabaseByReplicaID(replicaId)

		}

		if (databaseName != null) {
			return dbDirectory.openDatabase(databaseName, false)

		}

	}

}
