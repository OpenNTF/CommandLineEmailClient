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
import clenotes.ErrorLogger
import clenotes.Logger
import clenotes.utils.DxlUtils
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import lotus.domino.DateTime
import lotus.domino.Document
import lotus.domino.DocumentCollection
import lotus.domino.View

import static extension clenotes.utils.extensions.DocumentCollectionExtensions.*

class Search {

	def static execute(Command cmd) {

		var notesSession = CLENotesSession.getSession
		var mailDb = CLENotesSession::getMailDatabase()

		var DocumentCollection docCollection = null
		var fulltext = cmd.getOptionValue("fulltext")

		if (cmd.hasOption("view")) {

			if (fulltext == null) {
				ErrorLogger::error(-101, "Search option --fulltext must be specified when using view-search.")
				return
			}
			var viewName = cmd.getOptionValue("view")
			docCollection = searchView(viewName, fulltext)

		} else {

			var DateTime dt = notesSession.createDateTime("Yesterday")

			var adjustDay = CommandLineArguments::getValue("adjust-day")
			if (adjustDay != null) {
				dt.adjustDay(-Integer::parseInt(adjustDay))
			}

			// var DocumentCollection docCollection = mailDb.search("@All", dt)
			var subject = cmd.getOptionValue("subject")
			var sender = cmd.getOptionValue("from")
			var formula = cmd.getOptionValue("formula")
			var formulaFile = cmd.getOptionValue("formula-file")

			if (subject == null && sender == null && formula == null && formulaFile == null && fulltext == null) {
				ErrorLogger::error(-101, "Search option must be specified.")
				return
			}

			var mailSubjectSearchString = ""
			if (subject != null) {
				if (cmd.hasOption("self")) {
					mailSubjectSearchString = String.format('@Contains(Subject;"%s")', subject)

				} else {
					mailSubjectSearchString = String.format('@Contains(Subject;"%s") & !@Contains(From;"%s")', subject,
						notesSession.commonUserName)

				}
			}

			var mailSenderSearchString = ""
			if (sender != null) {
				mailSenderSearchString = String.format('@Contains(From;"%s") | @Contains(Principal;"%s")', sender,
					sender)

			}

			var String mailSearchString = null

			// if only subject search
			if (mailSubjectSearchString != "" && mailSenderSearchString == "") {
				mailSearchString = mailSubjectSearchString
			}

			// if only sender search
			if (mailSubjectSearchString == "" && mailSenderSearchString != "") {
				mailSearchString = mailSenderSearchString
			}

			// both subject and sender searches
			if (mailSubjectSearchString != "" && mailSenderSearchString != "") {
				mailSearchString = String.format("(%s) & (%s)", mailSenderSearchString, mailSubjectSearchString)
			}

			if (formulaFile != null) {

				// read formula from a file
				var file = new File(formulaFile)
				if (file.exists()) {
					var input = new FileInputStream(file)
					var output = new ByteArrayOutputStream
					var chr = input.read
					while (chr > -1) {
						output.write(chr)
						chr = input.read
					}
					input.close
					output.close
					formula = output.toString
				} else {
					println("[ERROR] File does not exist: " + file + ".")
				}
			}
			if (formula != null) {
				Logger::log("Formula: %s", formula)
				mailSearchString = formula
			}

			if (fulltext != null) {
				Logger::log("Full text search: %s", fulltext)
				docCollection = mailDb.FTSearch(fulltext);
			} else {
				Logger::log("Mail search string: %s", mailSearchString)
				if (adjustDay != null) {
					docCollection = mailDb.search(mailSearchString, dt, 0)
				} else {
					docCollection = mailDb.search(mailSearchString) // , dt, 0);
				}
			}
		}

		var matches = docCollection.getCount()
		Logger::log("Number of documents found: %d ", matches)

		docCollection = docCollection.sortDocumentCollectionIfNecessary(cmd)

		var readIndex = cmd.getOptionValue("read")
		if (readIndex == "*") {
			var n = 1
			var doc = docCollection.getNthDocument(n)
			while (doc != null) {
				var isDeleted = ReadMail::readMail(doc, cmd)
				n = n + 1
				doc.recycle()
				doc = docCollection.getNthDocument(n)
			}
		} else {

			var _readIndex = -1
			if (readIndex != null) {
				_readIndex = Integer::parseInt(readIndex)
			}

			if (readIndex == null && CommandLineArguments::hasOption("dxl")) {

				// if no --read specified but dxl is specified then print 
				// document collection as dxl 
				DxlUtils.exportDxl(docCollection)
				return
			}

			var values = docCollection.getMails(cmd, _readIndex, false)
			var numberOfMails = values.get(0)
			var outputTxt = values.get(1) as String
			var mailDoc = values.get(2) as Document

			if (mailDoc == null) {
				var txt = "mails"
				if(numberOfMails == 1) txt = "mail"
				println("Search returned " + numberOfMails + " " + txt + ".\r\n")
				println(outputTxt)

			} else {
				ReadMail::readMail(mailDoc, cmd)

			}
			if (mailDoc != null) {
				mailDoc.recycle
			}
		}

	}

	def static searchView(String viewName, String fulltext) {
		var mailDb = CLENotesSession::getMailDatabase()
		var View view = mailDb.getView(viewName)
		var docsMatched = view.FTSearch(fulltext, 0)
		Logger::log("Full text search from view '%s' using '%s' matched %d docs.", viewName, fulltext, docsMatched)

		// creates empty doccollection
		var docCollection = view.getAllDocumentsByKey("!###lip&%#)(/&")

		for (var i = 1; i <= docsMatched; i++) {
			var doc = view.getNthDocument(i)
			docCollection.addDocument(doc)
		}
		docCollection
	}

	def static searchDocuments() {
	}

}
