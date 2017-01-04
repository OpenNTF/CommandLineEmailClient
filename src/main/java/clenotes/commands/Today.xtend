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
import clenotes.utils.DxlUtils
import lotus.domino.DateTime
import lotus.domino.Document
import lotus.domino.DocumentCollection

import static extension clenotes.utils.extensions.DocumentCollectionExtensions.*

class Today {

	def static execute(Command cmd) {

		var _adjustDay = CommandLineArguments::getValue("adjust-day")
		var adjustDay = 0
		if (_adjustDay != null) {
			adjustDay = Integer::parseInt(_adjustDay)
		}

		var DocumentCollection docCollection = getMail(adjustDay, cmd.hasOption("all"))

		docCollection = docCollection.sortDocumentCollectionIfNecessary(cmd)

		//var matches = docCollection.getCount()
		//TODO: read index using list syntax: 45, 1:21, :21, 34: etc
		var readIndex = cmd.getOptionValue("read")

		if (readIndex != null && readIndex.equals("*")) {
			var n = 1
			var doc = docCollection.getNthDocument(n)
			while (doc != null) {
				ReadMail::readMail(doc, cmd)
				n = n + 1
				doc.recycle()
				doc = docCollection.getNthDocument(n)

			}
		} else {

			//TODO: go through mails and print todays mails
			var _readIndex = -1
			if (readIndex != null) {
				_readIndex = Integer::parseInt(readIndex)
			}

			if (readIndex == null && CommandLineArguments::hasOption("dxl")) {

				//if no --read specified but dxl is specified then print 
				//document collection as dxl 
				DxlUtils.exportDxl(docCollection)

				return
			}

			var values = docCollection.getMails( cmd, _readIndex, false)
			var numberOfMails = values.get(0)
			var outputTxt = values.get(1) as String
			var mailDoc = values.get(2) as Document

			if (mailDoc == null) {
				var txt = "mails"
				if(numberOfMails == 1) txt = "mail"
				var adjustedDay = ""
				if (adjustDay > 0) {
					adjustedDay = "-" + adjustDay

				}
				println(numberOfMails + " " + txt + " since yesterday" + adjustedDay + ".")
				println()
				println(outputTxt)

			} else {
				Logger::log("Reading mail... " + mailDoc.toString)
				ReadMail::readMail(mailDoc, cmd)

			}
		}

	}

	/*
	 * Return todays mails.
	 */
	def static getMail() {
		return getMail(0, false)
	}

	def static getMail(int adjustDay, boolean allDocuments) {
		var notesSession = CLENotesSession.getSession
		var mailDb = CLENotesSession::getMailDatabase()

		var DateTime dt = notesSession.createDateTime("Yesterday")

		if (adjustDay > 0) {
			dt.adjustDay(-adjustDay)
		}

		var DocumentCollection docCollection
		if (allDocuments) {
			docCollection = mailDb.search("@All", dt)
		} else {
			docCollection = mailDb.search(
				"From!=\"" + notesSession.getUserName() + "\" & (Form=\"Memo\" | Form=\"Reply\")", dt)
		}

		docCollection

	}

}
