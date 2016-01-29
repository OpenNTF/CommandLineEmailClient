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
import clenotes.Command
import clenotes.CommandLineArguments
import clenotes.Configuration
import clenotes.Logger
import clenotes.utils.Utils
import java.util.List
import lotus.domino.Database
import lotus.domino.DateTime
import lotus.domino.Document
import lotus.domino.DocumentCollection

import static extension clenotes.utils.extensions.DocumentExtensions.*

class DocumentCollectionExtensions {

	def static sortDocumentCollectionIfNecessary(DocumentCollection docCollection, Command cmd) {
		var sortOrder = cmd.getOptionValue("sortorder")
		var sortField = cmd.getOptionValue("sortfield")

		//sortOrder='ASC',sortField='DATE'
		//sort-field!: Sort mails by field. Use values DATE, SUBJECT or FROM. Default is DATE.
		var allowedOrders = #['ASC', 'DESC']
		var allowedFields = #['DATE', 'SUBJECT', 'FROM']

		if (sortOrder != null || sortField != null) {

			//do sorting if either field is not empty
			if(sortOrder == null) sortOrder = allowedOrders.get(0)
			if(sortField == null) sortField = allowedFields.get(0)

			if (!allowedOrders.contains(sortOrder)) {

				throw new IllegalArgumentException(
					'Sort order not recognized. Allowed sort orders: ' + allowedOrders.join(","))
			}

			if (!allowedFields.contains(sortField)) {

				throw new IllegalArgumentException(
					'Sort field not recognized. Allowed sort orders: ' + allowedFields.join(","))
			}
			var Database database = CLENotesSession::getMailDatabase
			var newDocCollection = database.getProfileDocCollection("PROFILE_THAT_SHOULD_STILL_NOT_EXIST")

			Logger::log("Sort by %s", sortField)
			var docsToBeSorted = newLinkedHashMap
			var n = 1
			var doc = docCollection.getNthDocument(n)
			while (doc != null) {

				//get sort field and doc uid and add to docstobesorted map
				//if docstobesorted includes key
				//get docid value and append it => so that sorting can be done
				var field = 'N/A'
				var docId = doc.getUniversalID()
				switch (sortField) {
					case "DATE": {
						var deliveredDate = doc.getSingleItemValue( 'DeliveredDate') as DateTime
						if (deliveredDate != null) {
							field = deliveredDate.toJavaDate.time.toString

						}
					}
					case "SUBJECT": {
						var subject = doc.getItemValueString("Subject")
						if (subject != null && subject.length > 0) {
							field = subject
						}
					}
					case "FROM": {
						var fromAddr = doc.getItemValueString("From")
						Logger::log("FROM: " + fromAddr)
						if (fromAddr != null && fromAddr.length > 0) {
							field = fromAddr
						}
					}
				}
				if (docsToBeSorted.containsKey(field)) {
					var old = docsToBeSorted.get(field)
					docsToBeSorted.put(field, old + " " + docId)
				} else {
					docsToBeSorted.put(field, docId)
				}

				n = n + 1
				doc.recycle()
				doc = docCollection.getNthDocument(n)
			} //end while doc !=null

			var sortedDocsFields = Utils::sortMap(docsToBeSorted)

			if (sortOrder.equals("DESC")) {
				sortedDocsFields.reverse
			}

			for (_field : sortedDocsFields) {
				var id = docsToBeSorted.get(_field)
				if (id.contains(" ")) {
					var idList = id.split(" ")
					for (_id : idList) {
						newDocCollection.addDocument(database.getDocumentByUNID(_id))

					}
				} else {
					newDocCollection.addDocument(database.getDocumentByUNID(id))
				}
			}

			return newDocCollection

		} //end if sortfield

		return docCollection

	}

	//(numberOfMails,outputTxt,mailDoc)=getMails(docCollection,opts,cmdOptions=cmdOpts,docReadIndex=readIndex)  
	def static List<?> getMails(DocumentCollection documentCollection, Command cmd, int docReadIndex, boolean noRange) {

		var outputFormatString = CommandLineArguments::getValue("output-format")
		var delimiter = CommandLineArguments::getValue("delim")
		if (CommandLineArguments::hasOption("tab")) {
			delimiter = "\t"
		}

		Logger::log("Doc read index: " + docReadIndex)
		var Document mailDocToBeRead = null

		/*
		if (docReadIndex > 0) {
			mailDocToBeRead = documentCollection.getNthDocument(docReadIndex-1)
			return #[0, "", mailDocToBeRead]
		}
*/
		var doc = documentCollection.getFirstDocument();
		var index = 0
		var listStartIndex = -1
		var listEndIndex = 10000
		var hasRangeIndex = false
		if (!noRange) {

			if (cmd.hasOption("start")) {
				listStartIndex = Integer::valueOf(cmd.getOptionValue("start"))
				hasRangeIndex = true
			}
			if (cmd.hasOption("end")) {
				listEndIndex = Integer::valueOf(cmd.getOptionValue("end"))
				hasRangeIndex = true
			}
		}

		var outputTxt = new StringBuffer
		var isReceivedMail = false
		var processDoc = false
		while (doc != null) {
			isReceivedMail = true
			if (docReadIndex == index) {
				mailDocToBeRead = doc

			}
			processDoc = false

			var deliveredDate = doc.getSingleItemValue("DeliveredDate")
			if(deliveredDate == null) isReceivedMail = false
			if (isReceivedMail) {
				processDoc = true
				if (hasRangeIndex) {
					if (index >= listStartIndex && index <= listEndIndex) {
						processDoc = true
					} else {
						processDoc = false
					}
				}

				//	}
				Logger::log(
					"index: " + index + " Prosessdoc: " + processDoc + ", start: " + listStartIndex + ", end: " +
						listEndIndex)
				if (processDoc) {
					if (outputFormatString != null) {
						outputTxt.append(getFormattedMail(doc, outputFormatString, index, delimiter))

					} else {
						outputTxt.append("[" + index + "] ")
						outputTxt.append(deliveredDate)
						outputTxt.append(Configuration::LINE_SEPARATOR)
						outputTxt.append("  ")
						if (doc.isSentByAgent()) {

							//fromField=doc.getItemValueString("Principal")
							outputTxt.append("From (Sent by agent?, probable sender): ")

						} else {

							//fromField=doc.getItemValueString("From")
							//principalField=doc.getItemValueString("Principal")
							//if principalField is not None and not "":
							//  if fromField!=principalField:
							//    principalField=principalField.strip()
							//    if principalField!=(""):
							//      fromField=principalField+" ("+fromField+")"
							outputTxt.append("From: ")

						}

						var fromField = doc.getItemValueString("From")
						var principalField = doc.getItemValueString("Principal")
						if (principalField != null && principalField != "") {
							if (fromField != principalField) {
								principalField = principalField.trim()
								if (principalField != "") {
									fromField = principalField + " (" + fromField + ")"
								}
							}
						}

						outputTxt.append(fromField)
						outputTxt.append(Configuration::LINE_SEPARATOR)
						outputTxt.append("  ")

						var subject = doc.getItemValueString("Subject")
						outputTxt.append("Subject: ")
						outputTxt.append(subject)
						outputTxt.append(Configuration::LINE_SEPARATOR)
						outputTxt.append("  ")

						var importance = doc.importance

						if (importance == "High") {
							outputTxt.append("High Importance")
							outputTxt.append(Configuration::LINE_SEPARATOR)
							outputTxt.append("  ")

						}

						outputTxt.append("Attachments: ")
						outputTxt.append(getAttachmentNames(doc, false))
						outputTxt.append(Configuration::LINE_SEPARATOR)
						outputTxt.append("  ")
					}
					outputTxt.append(Configuration::LINE_SEPARATOR)

				//index = index + 1
				}
				index = index + 1

			}
			doc = documentCollection.getNextDocument()

		}

		var mailTxt = outputTxt.toString
		#[index, mailTxt, mailDocToBeRead]

	//return rv//(index,mailTxt,mailDocToBeRead)
	}

	def static Document getLatestMailDocument(DocumentCollection documentCollection) {
		var doc = documentCollection.getLastDocument()
		while (doc != null) {
			var deliveredDate = doc.getSingleItemValue("DeliveredDate")
			if (deliveredDate != null) {
				return doc
			}
			doc = documentCollection.getPrevDocument()

		}
		null //should never happen

	}

	def static DocumentCollection getMailDocCollection(DocumentCollection docCollection, Database database, Command cmd) {

		var listStartIndex = -1
		var listEndIndex = 10000
		var hasRangeIndex = false
		if (cmd.hasOption("start")) {
			listStartIndex = Integer::valueOf(cmd.getOptionValue("start"))
			hasRangeIndex = true
		}
		if (cmd.hasOption("end")) {
			listEndIndex = Integer::valueOf(cmd.getOptionValue("end"))
			hasRangeIndex = true
		}
		if (!hasRangeIndex) {
			return docCollection
		}

		var index = 1
		var newDocCollection = database.getProfileDocCollection("PROFILE_THAT_SHOULD_STILL_NOT_EXIST")
		var doc = docCollection.getNthDocument(index)
		while (doc != null) {
			if (index >= listStartIndex && index <= listEndIndex) {
				newDocCollection.addDocument(doc)

			}
			index = index + 1
			doc = docCollection.getNthDocument(index)
		}

		return newDocCollection
	}

}
