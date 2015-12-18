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
import clenotes.Configuration
import clenotes.Logger
import clenotes.utils.DxlUtils
import clenotes.utils.Input
import clenotes.utils.Output
import lotus.domino.DateTime
import lotus.domino.Document
import lotus.domino.DocumentCollection

import static extension clenotes.utils.extensions.DocumentCollectionExtensions.*
import static extension clenotes.utils.extensions.DocumentExtensions.*

class ReadMail {

	def static readLatestMail(Command cmd) {

		var mailDb = CLENotesSession::getMailDatabase()

		var notesSession = CLENotesSession.getSession
		var DateTime dt = notesSession.createDateTime("Yesterday")

		var adjustDay = CommandLineArguments::getValue("adjust-day")
		if (adjustDay != null) {
			dt.adjustDay(-Integer::parseInt(adjustDay))

		}

		var DocumentCollection docCollection = mailDb.search("@All", dt)
		var doc = docCollection.getLatestMailDocument
		readMail(doc, cmd)
	}

	def static readMail(Document mailDocument, Command cmd) {
		var notesSession = CLENotesSession.getSession

		//var docToReturn = null
		if (CommandLineArguments::hasOption("dxl")) {
			DxlUtils.exportDxl(mailDocument)

			return false
		}

		if (cmd.hasOption("fields")) {
			mailDocument.printFields
			return false
		}

		if (cmd.hasOption("fieldvalues")) {
			mailDocument.printFieldValue(cmd.getOptionValue("fieldvalues"))
			return false
		}

		var replace = cmd.hasOption("replace")

		var printMailToScreen = true

		//reply
		if (cmd.hasOption("reply")) {
			var replyToAll = false
			if (cmd.hasOption("all")) {
				replyToAll = true

			}
			var replyDoc = mailDocument.createReplyMessage(replyToAll)
			replyDoc.replaceItemValue("Subject", "Re: " + mailDocument.getItemValueString("Subject"))
			replyDoc.replaceItemValue("From", notesSession.userNameObject.addr821)

			var body = getMailBody(mailDocument, cmd)
			var replyBody = ""
			if (cmd.hasOption("body")) {
				replyBody = cmd.getOptionValue("body")
			} else {
				var confirmation = Input::prompt("No reply body. Reply without body (yes/no)? ")
				confirmation = confirmation.toLowerCase.trim
				if (confirmation != "yes") {
					println("Use --body  to specify reply body.")
					return false
				}
			}

			replyBody = replyBody + "\n\n==================================================\n\n" + body

			replyDoc.replaceItemValue("Body", replyBody)
			replyDoc.replaceItemValue("$Mailer", Configuration::MAILER)
			replyDoc.setSaveMessageOnSend(true)

			replyDoc.send(mailDocument.getItemValueString("From"))

			println("Mail replied.")
			printMailToScreen = false
		}

		//TODO: forward
		//detach
		if (cmd.hasOption("detach-file") || cmd.hasOption("detach-all")) {
			var String dir = null
			if (cmd.hasOption("detach-dir")) {
				dir = cmd.getOptionValue("detach-dir")
			}
			var String attachmentToBeSaved = null
			if (cmd.hasOption("detach-file")) {
				attachmentToBeSaved = cmd.getOptionValue("detach-file")
			}
			var detachAllFiles = false
			if(cmd.hasOption("detach-all")) detachAllFiles = true
			mailDocument.getAttachmentNames(dir, attachmentToBeSaved, detachAllFiles, replace)
			printMailToScreen = false
		}

		//delete
		var isDeleted = false
		var confirmation = "no"
		if (cmd.hasOption("delete")) {

			if (cmd.hasOption("no-confirmation")) {
				confirmation = "yes"
			} else {
				var prompt = String.format("Delete mail from '%s' with subject '%s' (yes/no)? ",
					mailDocument.getItemValueString("From"), mailDocument.getItemValueString("Subject"))
				confirmation = Input::prompt(prompt)

				//var console = System::console
				//confirmation = console.readLine("Delete mail from '%s' with subject '%s'? (yes/no) ",
				//	mailDocument.getItemValueString("From"), mailDocument.getItemValueString("Subject"))
				confirmation = confirmation.toLowerCase.trim
			}

			if (confirmation == "yes") {
				isDeleted = true
				mailDocument.remove(false)
				println("Mail deleted.")

			} else {
				println("Mail not deleted.")

			}
			printMailToScreen = false

		}

		//move to folder
		if (cmd.hasOption("move-to-folder")) {

			var targetFolder = cmd.getOptionValue("move-to-folder")
			var sourceFolder = cmd.getOptionValue("folder") //undocumented, but kept if someone uses this
			if (sourceFolder == null) {
				sourceFolder = cmd.getOptionValue("source-folder")
			}

			Logger::log("Move mail from  " + targetFolder + " to " + sourceFolder)

			mailDocument.putInFolder(targetFolder)
			if (sourceFolder == null) {
				sourceFolder = "$Inbox"
			}
			mailDocument.removeFromFolder(sourceFolder)
			println("Mail moved to folder " + targetFolder + ".")
			return false
		}

		if (!printMailToScreen) {
			return isDeleted
		}

		//TODO: add principal field to mail list
		var deliveredDate = mailDocument.getSingleItemValue("DeliveredDate")
		println()
		var columnWidth = 20
		var lineStartIndentLevel = 0
		Output::prettyPrintln(#["Date :", deliveredDate.toString], columnWidth, lineStartIndentLevel)
		Output::prettyPrintln(#["From :", mailDocument.getItemValueString("From")], columnWidth, lineStartIndentLevel)
		Output::prettyPrintln(#["To :", mailDocument.getItemValues("SendTo")], columnWidth, lineStartIndentLevel)
		Output::prettyPrintln(#["Reply-To :", mailDocument.getItemValueString("ReplyTo")], columnWidth,
			lineStartIndentLevel)
		Output::prettyPrintln(#["Copy-To :", mailDocument.getItemValues("CopyTo")], columnWidth,
			lineStartIndentLevel)
		var importance = mailDocument.importance
		if (importance != null) {
			Output::prettyPrintln(#["Importance :", importance], columnWidth, lineStartIndentLevel)

		}
		Output::prettyPrintln(#["Subject :", mailDocument.getItemValueString("Subject")], columnWidth,
			lineStartIndentLevel)
		Output::prettyPrintln(#["Attachments :", mailDocument.getAttachmentNames(replace) as String], columnWidth,
			lineStartIndentLevel)
		var printBody = true
		if (cmd.hasOption("no-body")) {
			printBody = false
		}
		if (printBody) {
			Output::prettyPrintln(#["Body :"], columnWidth, lineStartIndentLevel)
			println(getMailBody(mailDocument, cmd))
		}
		return isDeleted

	}

	def static getMailBody(Document mailDocument, Command cmd) {
		var lineLen = -1
		if (cmd.hasOption("linelen")) {
			lineLen = Integer::parseInt(cmd.getOptionValue("linelen"))
		}
		mailDocument.getMailBody(lineLen)
	}
}
