/*
 * Copyright 2002, 2016 IBM Corp.
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
package clenotes.utils.extensions

import clenotes.CLENotesSession
import clenotes.Logger
import clenotes.utils.Output
import clenotes.utils.Utils
import java.util.Vector
import lotus.domino.DateTime
import lotus.domino.Document
import lotus.domino.EmbeddedObject
import lotus.domino.Item
import lotus.domino.MIMEEntity
import lotus.domino.RichTextItem
import static extension clenotes.utils.extensions.MIMEEntityExtensions.*

class DocumentExtensions {

	def static getSingleItemValue(Document doc, String itemName) {

		//By default Document.getItemValue() returns Vector even if item type is not
		//list. This function returns value of element instead of Vector that holds value.
		var value = doc.getItemValue(itemName) as Vector<?>
		var Object rValue = null
		if (value != null && value.size > 0) {
			rValue = value.firstElement
		} else {
			if (itemName == "DeliveredDate") {

				//if DeliveredDate missing, check PostedDate
				value = doc.getItemValue("PostedDate") as Vector<?>
				if (value != null && value.size > 0) {
					rValue = value.firstElement
				}
			}
		}
		rValue
	}

	def static getItemValues(Document doc, String itemName) {
		var value = doc.getItemValue(itemName) as Vector<?>
		var str = new StringBuffer
		for (v : value) {
			str.append(v)
			str.append(', ')

		}
		var values = str.toString
		if (values.length >= 2) {
			values = values.substring(0, values.length - 2)
		}
		return values

	}

	def static getMailBody(Document mailDocument, int lineLength) {

		var nativeMIME = mailDocument.getItemValueString("$NoteHasNativeMIME")
		nativeMIME = null
		if (nativeMIME != null && nativeMIME == "1") {
			"[Reading native MIME body not yet implemented]"

		//need to get all mime parts, check their contemt and encode
		//if necessary
		//add option to read mime mail like --mime
		} else {
			var body = mailDocument.getMailBody( "Body", lineLength)
			if (body.nullOrEmpty) {
				body = mailDocument.getMailBody( "$Body", lineLength)
			}
			body = Utils::removeMultipleEmptyLines(body)
			body

		}

	}

	def static getMailBody(Document mailDocument, String fieldName, int lineLength) {

		var bodyItems = mailDocument.getItemValue(fieldName)
		var size = bodyItems.size()
		Logger::log("Body items size: %d ", size)

		var tabstrip=false

		if (size == 1 && lineLength > -1) {

			//could be richtextitem and linelenght specified
			var item = mailDocument.getFirstItem(fieldName)
			Logger::log("Item class: %s", item.class.name)
			if (item instanceof RichTextItem) {
				var RichTextItem rtitem = item as RichTextItem
				
				var formattedBody = rtitem.getFormattedText(tabstrip, lineLength, 0)
				
				var body = rtitem.text
				Logger::log(
					"Rich text item Body size: " + body.length + ", formatted body size: " + formattedBody.length)
				return formattedBody
			}

		}

		//var body = mailDocument.getItemValueString("Body");
		var body = Utils::concatToString(bodyItems)
		if (body == "") {
			var item = mailDocument.getFirstItem(fieldName)
			if (item != null) {
				Logger::log("Getting body from: " + item.class.name)
			}
			switch (item) {
				case item instanceof RichTextItem: {
					var RichTextItem rtitem = item as RichTextItem
					var unformattedBody = rtitem.getFormattedText(tabstrip, 160, 0)
					body = rtitem.text
					Logger::log("Body size: " + body.length + ", unformatted body size: " + unformattedBody.length)
				}
				case item instanceof Item: {

					//likely a MIME email
					var Item _item = item as Item
					body = _item.getText()
					if (body == null) {
						var mimeEntity = _item.MIMEEntity
						body = mimeEntity.getText						
					}
				}
				case null: {
					body = "[Unable to get mail body]"
				}
			}
		}
		body
	}


	def static importance(Document mailDocument) {
		var importance = mailDocument.getItemValueString("Importance")
		if(importance == "1") return "High"
		if(importance == "2") return "Normal"
		null
	}

	def static String getAttachmentNames(Document doc, boolean replaceFile) {
		return doc.getAttachmentNames(null, null, false, replaceFile)
	}

	def static String getAttachmentNames(Document doc, String detachDir, String detachAttachmentName, boolean detachAll,
		boolean replaceFile) {
		Logger::log("Getting attachment names....")
		Logger::log("Document subject: " + doc.getSingleItemValue( "Subject"))
		Logger::log("Document form: " + doc.getSingleItemValue( "Form"))

		if ((detachAll || detachAttachmentName != null)) {
			println("Saving attachments from...")
			println("   " + getFormattedMail(doc, "!dtfs", 0, " "))
		}
		Logger::log("getAttachmentNames: " + doc)

		var hasNativeMIME = doc.hasItem("$NoteHasNativeMIME")

		var hasMIMEAttachments = hasNativeMIME && doc.hasEmbedded
		if (hasMIMEAttachments && (detachAll || detachAttachmentName != null)) {

			//detach native MIME attachments
			var names = ""
			names = detachMIMEAttachments(doc, detachDir, false, detachAttachmentName, replaceFile)
			return names
		}

		if (hasNativeMIME) {

			//for return only attachment names from native MIME mail
			return detachMIMEAttachments(doc, detachDir, true, detachAttachmentName, replaceFile)
		}

		if (hasNativeMIME) {
			var mimeEntity = doc.MIMEEntity
			Logger::log("Mime entity: " + mimeEntity)
		}

		var Item body = doc.getFirstItem("Body")
		if (body == null) {
			body = doc.getFirstItem("$Body");
		}
		var docAttachments = new Vector
		var str = new StringBuffer
		var someError = false

		if (body == null) {
			Logger::log("Body is null")
			Logger::log("  Subject: " + doc.getFirstItem("Subject"))
			Logger::log("  UNID   : " + doc.universalID)

		} else {
			Logger::log("Body item class: " + body.class.name)
			try {
				docAttachments = doc.embeddedObjects
				Logger::log("Attachments size from doc: " + docAttachments.size)
			} catch (Exception e) {
				someError = true
				str.append("[ERROR] Exception when getting attachments")

			}

			if (docAttachments.size == 0) {

				//cast item to RichTextItem and try to get attachments from that
				try {
					var RichTextItem rtitem = body as RichTextItem
					docAttachments = rtitem.embeddedObjects
					Logger::log("Attachments size from RichTextItem: " + docAttachments.size)
				} catch (Exception e) {

					//catch potential ClassCastException
					//reported bug in OpenNTF
					//http://www.openntf.org/internal/home.nsf/defect.xsp?action=openDocument&documentId=1152722592A1F85086257C3700354B19
					Logger::log(e)
				}
			}

			if (docAttachments.size == 0) {
				Logger::log("Check attachments from all items..")

				//still not found
				//check all items for attachments just in case
				var items = doc.items
				for (_item : items) {
					var item = _item as Item

					//Logger::log("item: " + item.name)
					if (item instanceof RichTextItem) {
						var rtitem = item as RichTextItem
						var eObjects = rtitem.embeddedObjects
						for (eo : eObjects) {
							docAttachments.add(eo)
						}
					} else {
						if (item.type == Item.ATTACHMENT) {

							//TODO: add option to disable rich text rendering
							//by using MIME
							Logger::log("File attachment found")
							Logger::log("  Doc has embedded: " + doc.hasEmbedded)
							var eObjects = doc.embeddedObjects
							for (eo : eObjects) {
								docAttachments.add(eo)
							}
							Logger::log("  Tota embedded: " + eObjects.size)
							Logger::log("  class: " + item.class.name)
							Logger::log("  name: " + item.name)
							Logger::log("  text: " + item.text)
							Logger::log("  value length: " + item.valueLength)
							Logger::log("  valuestring: " + item.valueString.trim)

						//add name to list
						//and extract if needed
						}
					}
				}
			}
		}

		for (o : docAttachments) {
			var EmbeddedObject a = o as EmbeddedObject
			Logger::log("EmbeddedObject: " + a.name)
			if (a.type == EmbeddedObject::EMBED_ATTACHMENT) {
				var fileName = a.name
				str.append(fileName)
				str.append(", ")
				var dir = "."
				if (detachAll || detachAttachmentName != null) {
					if (detachDir != null) {
						Logger::log("detach-dir: " + dir)
						dir = detachDir.replace('\\', '/')

						//dir=dir.replace('/','\\\\')
						if(!dir.endsWith("/")) dir = dir + "/"
						Logger::log("detach-dir modified: " + dir)
					} else {
						dir = "./"

					}

					//print "detachAll",detachAll
					var extractedFile = dir + fileName
					if (!replaceFile) { //if --replace option not specified, modify file name
						extractedFile = Utils::checkIfFileExists(extractedFile)
					}

					if (detachAll || fileName == detachAttachmentName) {
						a.extractFile(extractedFile)
						println("   Attachment saved: " + extractedFile + ".")
					}
				}
			}
		}

		var names = str.toString
		if (names.endsWith(",")) {
			names = names.substring(0, names.length - 1)
		}

		if (names.length == 0 && hasMIMEAttachments) {
			names = "[MIME attachments not yet implemented]"
		}
		return names
	}


	def static getFormattedMail(Document mailDoc, String _formatString, int index, String _delimiter) {
		var delimiter = _delimiter
		if(delimiter == null) delimiter = ";"
		var txt = new StringBuffer
		if (_formatString.indexOf("!") == -1) {
			txt.append(index)
			txt.append(delimiter)
		}
		var datetime = mailDoc.getSingleItemValue("DeliveredDate") as DateTime

		//mailDoc.getItemValueDateTimeArray("DeliveredDate").get(0) as DateTime
		var formatString = _formatString.toCharArray
		for (_chr : formatString) {
			var chr = Character::toString(_chr)
			switch (chr) {
				case 'd': {
					if (datetime == null) {
						txt.append("N/A")
					} else {
						txt.append(datetime.getDateOnly())
					}
					txt.append(delimiter)

				}
				case 't': {
					if (datetime == null) {
						txt.append("N/A")
					} else {
						txt.append(datetime.getTimeOnly())
					}
					txt.append(delimiter)

				}
				case 'Z': {

					if (datetime == null) {
						txt.append("N/A")
					} else {
						txt.append(datetime.getTimeZone())
					}

					//if datetime.isDST():
					//  txt.write(' (DST)')
					txt.append(delimiter)
				}
				case 'g': {

					if (datetime == null) {
						txt.append("N/A")
					} else {
						txt.append(datetime.getGMTTime())
					}

					txt.append(delimiter)
				}
				case 's': {

					var value = mailDoc.getItemValueString("Subject")
					txt.append(value)
					txt.append(delimiter)
				}
				case 'f': {
					var value = mailDoc.getItemValueString("From")
					txt.append(value)
					txt.append(delimiter)
				}
				case 'I': {
					var value = mailDoc.getItemValueString("INetFrom")
					txt.append(value)
					txt.append(delimiter)

				}
				case 'm': {
					var value = mailDoc.getItemValueString("$Mailer")
					txt.append(value)
					txt.append(delimiter)

				}
				case 'D': {
					var value = mailDoc.getItemValueString("$MessageID")
					txt.append(value)
					txt.append(delimiter)

				}
				case 'S': {
					var value = mailDoc.getSize()
					txt.append(value)
					txt.append(delimiter)

				}
				case 'a': {
					var value = getAttachmentNames(mailDoc, false) as String
					if (value.nullOrEmpty) {
						value = "n/a"
					}
					txt.append(value)
					txt.append(delimiter)

				}
			}
		}

		var rv = txt.toString
		return rv.substring(0, rv.length - delimiter.length) //#removes delimiter at the end
	}

	def static detachMIMEAttachments(Document doc, String _detachDir, boolean getNamesOnly, String attachmentName,
		boolean replaceFile) {
		var names = ""
		var session = CLENotesSession.session
		session.setConvertMIME(false)

		var MIMEEntity mime = doc.getMIMEEntity();

		if (mime != null) {

			// If multipart MIME entity
			if (mime.getContentType().equals("multipart")) {

				var MIMEEntity child1 = mime.getFirstChildEntity();

				while (child1 != null) {

					var contentType = child1.contentType
					if (contentType == "application") {
						var String name = null
						name = child1.detachAttachment( _detachDir, getNamesOnly, attachmentName, replaceFile)

						if (!name.nullOrEmpty) {
							names = names + name + ","
						}
					}

					var MIMEEntity child2 = child1.getFirstChildEntity();

					if (child2 == null) {

						child2 = child1.getNextSibling();
						if (child2 == null) {
							child2 = child1.getParentEntity();
							if (child2 != null)
								child2 = child2.getNextSibling();
						}
					}
					child1 = child2;
				}
			} else {
				var contentType = mime.contentType
				if (contentType == "application") {
					var String name = null
					name = mime.detachAttachment( _detachDir, getNamesOnly, attachmentName, replaceFile)
				}
			}
		}

		session.setConvertMIME(true)
		if (names != null && names.endsWith(",")) {
			names = names.substring(0, names.length - 1)
		}
		names
	}

	def static printFields(Document document) {

		//list fields and types in the document
		var items = document.items

		var columnFields = newHashMap()
		for (_item : items) {
			var item = _item as Item
			var name = item.name
			var _type = item.type
			var className = item.class.name
			var type = ""
			switch (_type) {
				case Item.ACTIONCD: {
					type = "ACTIONCD"
				}
				case Item.ASSISTANTINFO: {
					type = "ASSISTANTINFO"
				}
				case Item.ATTACHMENT: {
					type = "ATTACHMENT (file attachment)"
				}
				case Item.AUTHORS: {
					type = "AUTHORS"
				}
				case Item.COLLATION: {
					type = "COLLATION"
				}
				case Item.DATETIMES: {
					type = "DATETIMES (date-time or range of date-time values)"
				}
				case Item.EMBEDDEDOBJECT: {
					type = "EMBEDDEDOBJECT"
				}
				case Item.ERRORITEM: {
					type = "ERRORITEM (error occurred while getting type)"
				}
				case Item.FORMULA: {
					type = "FORMULA (Domino formula)"
				}
				case Item.HTML: {
					type = "HTML (HTML source text)"
				}
				case Item.ICON: {
					type = "ICON"
				}
				case Item.LSOBJECT: {
					type = "LSOBJECT"
				}
				case Item.MIME_PART: {
					type = "MIME_PART"
				}
				case Item.NAMES: {
					type = "NAMES"
				}
				case Item.NOTELINKS: {
					type = "NOTELINKS (link to a database, view, or document)"
				}
				case Item.NOTEREFS: {
					type = "NOTEREFS (reference to the parent document)"
				}
				case Item.NUMBERS: {
					type = "NUMBERS (number or number list)"
				}
				case Item.OTHEROBJECT: {
					type = "OTHEROBJECT"
				}
				case Item.QUERYCD: {
					type = "QUERYCD"
				}
				case Item.READERS: {
					type = "READERS"
				}
				case Item.RFC822TEXT: {
					type = "RFC822TEXT"
				}
				case Item.RICHTEXT: {
					type = "RICHTEXT"

				}
				case Item.SIGNATURE: {
					type = "SIGNATURE"
				}
				case Item.TEXT: {
					type = "TEXT (text or text list)"
				}
				case Item.UNAVAILABLE: {
					type = "UNAVAILABLE"
				}
				case Item.UNKNOWN: {
					type = "UNKNOWN"
				}
				case Item.USERDATA: {
					type = "USERDATA"
				}
				case Item.USERID: {
					type = "USERID"
				}
				case Item.VIEWMAPDATA: {
					type = "VIEWMAPDATA"
				}
				case Item.VIEWMAPLAYOUT: {
					type = "VIEWMAPLAYOUT"
				}
				default: {
					type = "undetermined"
				}
			}
			columnFields.put(name, type + "," + className)

		}

		var sortedNames = columnFields.keySet.sort
		var index = 1
		var printIndex = false
		println("Total fields: " + sortedNames.size)
		var list = newArrayList()
		list.add("NAME")
		list.add("TYPE")

		//list.add("Java class")
		Output.prettyPrintln(list, 30, 0)
		for (name : sortedNames) {
			list = newArrayList()
			var indexS = ""
			if (printIndex) {
				if (index < 10) {
					indexS = index + " : "
				} else {
					indexS = index + ": "
				}
			}
			list.add(indexS + name)
			var typeAndClass = columnFields.get(name).split(",")
			list.add(typeAndClass.get(0))

			//list.add(typeAndClass.get(1))
			Output.prettyPrintln(list, 30, 0)
			index = index + 1
		}
	}

	def static printFieldValue(Document document, String fieldName) {
		if (!document.hasItem(fieldName)) {
			println("Field " + fieldName + " does not exist.")
			return
		}

		println("Field " + fieldName + ":")
		var itemValues = document.getItemValue(fieldName)

		if (itemValues.size == 0) {
			println("  N/A")
		}
		for (value : itemValues) {
			println("  " + value)
		}
	}


}
