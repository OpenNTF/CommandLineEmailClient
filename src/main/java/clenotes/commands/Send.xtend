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
import clenotes.Configuration
import clenotes.Logger
import clenotes.utils.Utils
import java.io.BufferedReader
import java.io.File
import java.io.FileInputStream
import java.io.InputStreamReader
import java.nio.charset.Charset
import java.util.Map
import java.util.Vector
import lotus.domino.EmbeddedObject
import lotus.domino.MIMEEntity
import clenotes.ErrorLogger

class Send {

	def static execute(Command cmd) {

		var mailDb = CLENotesSession::getMailDatabase()

		var newMailDocument = mailDb.createDocument()

		var notesSession = CLENotesSession.getSession

		var sender = notesSession.getUserName()

		//add principal field so that mail appears to come from someone else
		//remember to add NotesDomain after sender email
		//for example use this option: --from=sender@somewhere.com@NotesDomain
		var principal = cmd.getOptionValue("principal")
		if (principal != null) {
			newMailDocument.replaceItemValue("Principal", principal)

		}

		var subject = cmd.getOptionValue("subject")

		/*
  
 		var subjectList = cmd.getOptionValues("subject")
		var subject=""
		if(subjectList!=null )
		{
			if(subjectList.size >1)
			{
				subject=subjectList.join(",")
			}
			else
			{
				subject=subjectList.get(0)
			}
		}
*/
		var toList = cmd.getOptionValues("to")
		var toFile = cmd.getOptionValue("file-to")
		if (toList == null && toFile == null) {
			println("Mail not sent.")
			ErrorLogger::error(-102, "Recipient not specified. Use --to or --file-to to set recipient.")
			return
		}

		var toVector = new Vector()
		var Vector<String> ccVector = null
		var Vector<String> bccVector = null

		if (toList != null) {
			for (to : toList) {
				toVector.add(to.trim())
			}
		}

		if (toFile != null) {
			toVector = Utils::readFileToVector(toFile)

		}

		var ccList = cmd.getOptionValues("cc")
		if (ccList != null) {
			ccVector = new Vector()
			for (cc : ccList) {
				ccVector.add(cc.trim())
			}
		}

		var ccFile = cmd.getOptionValue("file-cc")
		if (ccFile != null) {
			ccVector = Utils::readFileToVector(ccFile)

		}

		var bccList = cmd.getOptionValues("bcc")
		if (bccList != null) {
			bccVector = new Vector()
			for (bcc : bccList) {
				bccVector.add(bcc.trim())
			}
		}

		var bccFile = cmd.getOptionValue("file-bcc")
		if (bccFile != null) {
			bccVector = Utils::readFileToVector(bccFile)
		}

		Logger::log("To  list: " + toVector)
		Logger::log("Cc  list: " + ccVector)
		Logger::log("Bcc list: " + bccVector)

		var postedDate = notesSession.createDateTime("Today");
		postedDate.setNow();
		Logger::log("Posted date: " + postedDate)
		newMailDocument.replaceItemValue("PostedDate", postedDate)
		
		newMailDocument.replaceItemValue("Form", "Memo")
		newMailDocument.replaceItemValue("From", sender)
		newMailDocument.replaceItemValue("SendTo", toVector)
		if (ccList != null) {

			//#TODO loop list and make comma seprated string 
			newMailDocument.replaceItemValue("CopyTo", ccVector)
		}
		if (bccList != null) {
			newMailDocument.replaceItemValue("BlindCopyTo", bccVector)
		}

		var replyTo = cmd.getOptionValue("replyto")
		if (replyTo != null) {
			newMailDocument.replaceItemValue("ReplyTo", replyTo)
		}

		newMailDocument.replaceItemValue("Subject", subject)
		newMailDocument.replaceItemValue("$Mailer", Configuration::MAILER)

		if (cmd.hasOption("urgent")) {
			newMailDocument.replaceItemValue("Importance", "1")
		}

		if (cmd.hasOption("encrypt")) {
			newMailDocument.setEncryptOnSend(true)
		}

		if (cmd.hasOption("sign")) {
			newMailDocument.setSignOnSend(true)
		}

		var body = cmd.getOptionValue("body")
		if (body != null) {
			body = body.replace('\\n', '\n')
		}

		if (Configuration::logEnabled) {
			Logger::log("default charset: " + Charset.defaultCharset.name)
			var Map<String, Charset> availableCharsets = Charset.availableCharsets;
			Logger::log("Available charsets:")
			for (charset : availableCharsets.keySet) {
				Logger::log("  " + availableCharsets.get(charset).name)
			}
		}

		var bodyFile = cmd.getOptionValue("file-body")
		if (bodyFile != null) {

			//TODO: add option to specify charset
			var charsetName = cmd.getOptionValue("charset")
			if (charsetName == null) {
				charsetName = "UTF-8"
			}

			var charset = Charset.forName(charsetName)

			Logger::log("Reading body file using charset: " + charset.name)

			var f = new BufferedReader(new InputStreamReader(new FileInputStream(bodyFile), charset))

			var bodyLines = newArrayList
			var line = f.readLine()
			while (line != null) {
				bodyLines.add(line + "\n")
				line = f.readLine()
			}

			f.close()
			if (body == null) {
				body = bodyLines.join("")
			} else {
				body = body + "\n\n" + bodyLines.join("")
			}
		}

		if (cmd.hasOption("html")) {

			//send as html mail
			var stream = notesSession.createStream()
			notesSession.setConvertMIME(false) //# Do not convert MIME to RT

			var mimeBody = newMailDocument.createMIMEEntity();
			var header = mimeBody.createHeader("Content-Type");
			header.setHeaderVal("multipart/mixed");

			//#create mime entity for body
			var bodyEntity = mimeBody.createChildEntity()
			stream.writeText(body);
			bodyEntity.setContentFromText(stream, 'text/html;charset="UTF-8"', MIMEEntity.ENC_NONE)

			var sigList = getSignature(cmd)
			var String signature = sigList.get(0)
			var String signatureFile = sigList.get(1)

			//Add signature from command line option
			if (signature != null) {
				var signatureEntity = mimeBody.createChildEntity()
				stream = notesSession.createStream();
				stream.writeText(signature);
				signatureEntity.setContentFromText(stream, 'text/html;charset="UTF-8"', MIMEEntity.ENC_NONE)
			}

			//#Add signature from file
			if (signatureFile != null) {
				var signatureEntity = mimeBody.createChildEntity()
				stream = notesSession.createStream();
				stream.writeText(signatureFile);
				signatureEntity.setContentFromText(stream, 'text/html;charset="UTF-8"', MIMEEntity.ENC_NONE)
			}

			//#Attachments
			var attachmentList = cmd.getOptionValues("attach")
			if (attachmentList != null) {
				for (attachment : attachmentList) {
					var attachmentEntity = mimeBody.createChildEntity()
					var _header = attachmentEntity.createHeader("Content-Disposition");
					val file=new File(attachment)
					var filename=file.name
					if (filename=="")
					{
						filename=attachment
					}
					_header.setHeaderVal("attachment;filename=" + filename);
					stream = notesSession.createStream();
					var fileInput = new FileInputStream(attachment);
					stream.setContents(fileInput)
					attachmentEntity.setContentFromBytes(stream, "application/octet-stream",
						MIMEEntity.ENC_IDENTITY_BINARY)
					fileInput.close()
				}
			}

			notesSession.setConvertMIME(true);

		//#TODO:
		//#use --alttext as alternative text for html mails
		} else {
			if (body != null) {
				var richTextBody = newMailDocument.createRichTextItem("Body")
				richTextBody.appendText(body)
				var sigList = getSignature(cmd)
				var signature = sigList.get(0)
				var signatureFile = sigList.get(1)

				if (signature != null) {
					richTextBody.appendText("\n\n" + signature)
				}

				if (signatureFile != null) {
					richTextBody.appendText("\n\n" + signatureFile)
				}

				var attachmentList = cmd.getOptionValues("attach")
				if (attachmentList != null) {
					for (attachment : attachmentList) {
						var file = new File(attachment)
						richTextBody.embedObject(EmbeddedObject.EMBED_ATTACHMENT, null, file.getAbsolutePath(), null)						
						richTextBody.update						
					}
				}
				richTextBody.update						
				
			}
		}

		if (!cmd.hasOption("nosave")) {
			newMailDocument.save()
		}

		if (cmd.hasOption("html")) {
			newMailDocument.send(false)
		} else {
			newMailDocument.send()
		}

		var toStr = toVector.get(0)
		var andOthers = ""
		if (toVector.size > 1) {
			andOthers = " and others"
		}

		println("Mail sent to " + toStr + andOthers + " with subject: " + subject)

	}

	def static getSignature(Command cmd) {
		var String signature = null
		var String signatureFile = null

		if (cmd.hasOption("signature")) {
			signature = cmd.getOptionValue("signature")
			signature = signature.replace('\\n', '\n')
		}

		if (cmd.hasOption("file-signature")) {
			var _signatureFile = cmd.getOptionValue("file-signature")
			var f = new BufferedReader(new InputStreamReader(new FileInputStream(_signatureFile)))

			var lines = newArrayList
			var line = f.readLine()
			while (line != null) {
				lines.add(line + "\n")
				line = f.readLine()
			}
			f.close()

			signatureFile = lines.join("")
		}

		var returnValue = newArrayOfSize(2)
		returnValue.set(0, signature)
		returnValue.set(1, signatureFile)

		return returnValue
	}
}
