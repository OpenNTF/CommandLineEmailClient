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
import clenotes.CommandLineArguments
import clenotes.Configuration
import clenotes.Logger
import clenotes.utils.Utils
import java.io.File
import lotus.domino.MIMEEntity
import lotus.domino.MIMEHeader
import lotus.domino.Stream

class MIMEEntityExtensions {

	def static getText(MIMEEntity mime) {

		var text = new StringBuffer()

		// If multipart MIME entity
		val mimeContentType = mime.getContentType()
		Logger::log("Mime content type: %s", mimeContentType)
		if (mimeContentType.equals("multipart")) {
			var MIMEEntity child1 = mime.getFirstChildEntity();
			var textAlreadyExtracted = false
			while (child1 != null) {

				var contentType = child1.contentType
				if (contentType == "text" && !textAlreadyExtracted) {
					if (CommandLineArguments::hasOption("all-mime-texts")) {
						text.append("==MIME part: " + contentType + "/" + child1.contentSubType)
						text.append(Configuration::LINE_SEPARATOR)
					}

					text.append(getContentAsText(child1))
					if (!CommandLineArguments::hasOption("all-mime-texts")) {
						textAlreadyExtracted = true
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
			if (contentType == "text") {
				text.append(getContentAsText(mime))
			}
		}

		text.toString
	}

	def static getContentAsText(MIMEEntity mime) {
		var text = new StringBuffer()
		var subContentType = mime.contentSubType
		Logger::log("mime subcontenttype: %s. Encoding: %s (is decoded, if necessary)", subContentType, mime.encodingString)
		mime.decodeContent()
		switch (subContentType) {
			case "html": {
				var txt = mime.contentAsText
				if (!CommandLineArguments::hasOption("no-striphtmltags")) {

					// remove html tags
					// check if HTML has HEAD tag
					// if so, remove
					var lowerTxt = txt.toLowerCase
					if (lowerTxt.contains("<head>")) {
						var start = lowerTxt.indexOf("<head>")
						var end = lowerTxt.indexOf("</head>")
						txt = txt.substring(0, start) + txt.substring(end, txt.length)
					}

					txt = txt.replaceAll("<[^>]*>", "")
				}
				text.append(txt)
			}
			default: {
				text.append(mime.contentAsText)
			}
		}
		text.append(Configuration::LINE_SEPARATOR)
		text.toString
	}

	def static detachAttachment(MIMEEntity mimeEntity, String _detachDir, boolean getNamesOnly, String attachmentName,
		boolean replaceFile) {

		var String name = null
		var detachDir = _detachDir
		if (detachDir == null) {
			detachDir = "./"
		}
		var _dir = new File(detachDir)
		var dir = _dir.canonicalPath
		if (!dir.endsWith("/") && !dir.endsWith("\\")) {
			dir = dir + "/"
		}

		mimeEntity.decodeContent
		printMIMEHeaders(mimeEntity)
		var header = mimeEntity.getNthHeader("Content-Disposition")
		if (header != null) {
			if (header.headerVal == "attachment") {

				// attachment exists
				// note: inline attachments not supported
				name = header.getParamVal("filename")
				name = name.replace("\"", "").trim

				// save attachment only if saving all attachments or attachment name
				// contains given attachmentname
				if (!getNamesOnly && (attachmentName == null || name.contains(attachmentName))) {
					var session = CLENotesSession.session
					var Stream stream = session.createStream();

					var filePath = dir + name
					if (!replaceFile) { // if --replace option not specified, modify file name
						filePath = Utils::checkIfFileExists(filePath)
					}
					if (stream.open(filePath, "binary")) {
						mimeEntity.getContentAsBytes(stream)
						stream.close
						println("   Attachment saved: " + name + ".")
					} else {
						println("   Failed to detach: " + name + ".")
					}
				}
			}
		}
		name
	}

	def static printMIMEHeaders(MIMEEntity mimeEntity) {
		var headers = mimeEntity.headerObjects
		Logger::log("=== MIME Entity: " + mimeEntity.toString)
		for (_header : headers) {
			var MIMEHeader header = _header as MIMEHeader

			Logger::log(header.headerName)
			Logger::log("  value : " + header.getHeaderVal())
			Logger::log("  value and params: " + header.headerValAndParams)
		}
	}

	def static getEncodingString(MIMEEntity mime) {
		var encodingString = ""
		switch (mime.encoding) {
			case MIMEEntity.ENC_BASE64: encodingString = "base64"
			case MIMEEntity.ENC_EXTENSION: encodingString = "Extension"
			case MIMEEntity.ENC_IDENTITY_7BIT: encodingString = "7bit"
			case MIMEEntity.ENC_IDENTITY_8BIT: encodingString = "8bit"
			case MIMEEntity.ENC_IDENTITY_BINARY: encodingString = "binary"
			case MIMEEntity.ENC_NONE: encodingString = "None"
			case MIMEEntity.ENC_QUOTED_PRINTABLE: encodingString = "quoted-printable"
			default: encodingString = "Should not happen"
		}
		encodingString
	}

}