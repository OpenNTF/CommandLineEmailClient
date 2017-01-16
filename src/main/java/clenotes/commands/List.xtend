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
import clenotes.ErrorLogger
import clenotes.Logger
import clenotes.utils.DxlUtils
import lotus.domino.Document
import lotus.domino.DocumentCollection

import static extension clenotes.utils.extensions.DatabaseExtensions.*
import static extension clenotes.utils.extensions.DocumentCollectionExtensions.*
import static extension clenotes.utils.extensions.DocumentExtensions.*

class List {

	def static execute(Command cmd) {

		var mailDb = CLENotesSession::getMailDatabase()

		var docCollection = null as DocumentCollection

		var folderViewName = cmd.getOptionValue("folderview")
		// get documents from view
		// some folders may be views in Notes database
		if (folderViewName != null) {

			// create empty doc collection
			docCollection = mailDb.getProfileDocCollection("PROFILE_THAT_SHOULD_NOT_EXIST")
			var folderView = mailDb.getView(folderViewName)
			if (folderView == null) {
				// if folder view is not found try to check if it starts with $
				// for exampe Inbox-folder is named "Inbox" but view is "$Inbox"
				Logger::log("Folder view '" + folderViewName + "' not found. Trying '$" + folderViewName + "'...")
				folderView = mailDb.getView("$" + folderViewName)
			}
			if (folderView == null) {
				if (ErrorLogger.errorCode != 0) {
					ErrorLogger::error(-108, "Folder (view) '" + folderViewName + "' not found.")
				}
				return
			}
			var viewEntryCollection = folderView.getAllEntries()
			var viewEntry = viewEntryCollection.getFirstEntry()
			while (viewEntry != null) {
				var doc = viewEntry.getDocument()
				if (doc != null) {
					
					//TODO: check if adjust-day is present and add only those documents
					//that match
					
					docCollection.addDocument(doc)

				}
				viewEntry = viewEntryCollection.getNextEntry()
			}

		} else {

			var folderName = cmd.getOptionValue("folder")

			var String folderID = null
			if (folderName != null) {

				folderID = mailDb.getFolderID(folderName)
				if (folderID == null) {
					if (ErrorLogger.errorCode != 0) {
						ErrorLogger::error(-109, "Folder '" + folderName + "' not found.")
					}
					return
				} else {
					Logger::log(
						"Folder '" + folderName + "' found. Searching all documents containing $FolderRef='" +
							folderID + "'")
				}

			}

			var adjustDay = -1
			var adjustDayOption = cmd.getOptionValue("adjust-day")
			// CommandLineArguments::getValue("adjust-day")
			if (adjustDayOption != null) {
				adjustDay = Integer::parseInt(adjustDayOption)
			}
			if (cmd.hasOption("all")) {
				docCollection = mailDb.findAllDocuments(adjustDay)
			} else {
				docCollection = mailDb.findMailDocuments(adjustDay, folderID)
			}

		}

		if (cmd.hasOption("checkMIME")) {
			println("Checking MIME emails...")
			var n = 1
			var doc = docCollection.getNthDocument(n)
			while (doc != null) {
				var hasNativeMIME = doc.hasItem("$NoteHasNativeMIME")
				if (hasNativeMIME) {
					var deliveredDate = doc.getSingleItemValue("DeliveredDate")
					var subject = doc.getItemValueString("Subject")
					println(deliveredDate + ": " + subject)
					println(doc.getAttachmentNames(false))
				}
				n = n + 1
				doc.recycle()
				doc = docCollection.getNthDocument(n)
			}

		} else {
			handleDocumentCollection(docCollection, cmd)

		}

	}

	def static handleDocumentCollection(DocumentCollection _docCollection, Command cmd) {

		// should sort be later? after DominoUtils::getMails?
		var docCollection = _docCollection.sortDocumentCollectionIfNecessary(cmd)
		var readIndex = cmd.getOptionValue("read")

		if (readIndex == "*") {
			var n = 1
			var doc = _docCollection.getNthDocument(n)
			while (doc != null) {
				var isDeleted = ReadMail::readMail(doc, cmd)
				n = n + 1
				doc.recycle()
				doc = _docCollection.getNthDocument(n)
			}

		} else {
			var rIndex = -1
			if (readIndex != null) {
				rIndex = Integer::parseInt(readIndex)
			}

			if (readIndex == null && cmd.hasOption("dxl")) {
				// if no --read specified but dxl is specified then print 
				// document collection as dxl 
				DxlUtils.exportDxl(docCollection)

				return
			}

			// return from getMails is a list		#[index, mailTxt, mailDocToBeRead]
			var mails = docCollection.getMails(cmd, rIndex, false)
			var numberOfMails = mails.get(0)
			var mailTxt = mails.get(1) as String
			var mailDoc = mails.get(2) as Document

			if (mailDoc == null) {
				var adjustDay = cmd.getOptionValue("adjust-day")
				var txt = "mails"
				if(numberOfMails == 1) txt = "mail"

				if (adjustDay != null && adjustDay == "0") {
					println(numberOfMails + " " + txt + " since yesterday.")
				} else {
					println("Listing " + numberOfMails + " " + txt + ".")
				}

				println()
				println(mailTxt)

			} else {
				ReadMail::readMail(mailDoc, cmd)
			}
		}
	}
}
