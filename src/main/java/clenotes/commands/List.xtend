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
package clenotes.commands

import clenotes.CLENotesSession
import clenotes.Command
import clenotes.CommandLineArguments
import clenotes.utils.DxlUtils
import lotus.domino.DateTime
import lotus.domino.Document
import lotus.domino.DocumentCollection

import static extension clenotes.utils.extensions.DocumentCollectionExtensions.*
import static extension clenotes.utils.extensions.DocumentExtensions.*

class List {

	def static execute(Command cmd) {

		var folder = cmd.getOptionValue("folder")

		var mailDb = CLENotesSession::getMailDatabase()
		
		var notesSession=CLENotesSession.getSession
		
		var docCollection = null as DocumentCollection
		if (folder != null) {

			//create empty doc collection using method below
			docCollection = mailDb.getProfileDocCollection("PROFILE_THAT_SHOULD_NOT_EXIST")

			//folder is View, use Views api
			//request from user:
			//1. Read each mail document under a given folder.
			//  For each document under the folder,
			//  2. Detach all its attachments
			//  3. Move the document to another given folder.
			var folderView = mailDb.getView(folder)
			var viewEntryCollection = folderView.getAllEntries()
			var viewEntry = viewEntryCollection.getFirstEntry()
			while (viewEntry != null) {
				var doc = viewEntry.getDocument()
				if (doc != null) {
					docCollection.addDocument(doc)

				}
				viewEntry = viewEntryCollection.getNextEntry()

			}

		} else {

			var DateTime dt = null

			var adjustDay = CommandLineArguments::getValue("adjust-day")
			if (adjustDay != null) {
				dt = notesSession.createDateTime("Yesterday")
				dt.adjustDay(-Integer::parseInt(adjustDay))
			}

			//If searching @All, all document returned, memos, reply, invitations etc
			if (cmd.hasOption("all")) {
				docCollection = mailDb.search("@All", dt)
			} else {
				docCollection = mailDb.search(
					"From!=\"" + notesSession.getUserName() + "\" & (Form=\"Memo\" | Form=\"Reply\")", dt)
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
					println(doc.getAttachmentNames( false))
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

		//should sort be later? after DominoUtils::getMails?
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

			if(readIndex==null && CommandLineArguments::hasOption("dxl"))
			{
				//if no --read specified but dxl is specified then print 
				//document collection as dxl 
				DxlUtils.exportDxl(docCollection)
	
				return
			}


			//return from getMails is a list		#[index, mailTxt, mailDocToBeRead]
			var mails = docCollection.getMails( cmd, rIndex, false)
			var numberOfMails = mails.get(0)
			var mailTxt = mails.get(1) as String
			var mailDoc = mails.get(2) as Document

			if (mailDoc == null) {
				var txt = "mails"
				if(numberOfMails == 1) txt = "mail"
				println("Listing " + numberOfMails + " " + txt + ".")
				println(mailTxt)

			} else {
				ReadMail::readMail(mailDoc, cmd)

			}
		}
	}
}
