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
package clenotes.commands.shell;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.util.Enumeration;
import java.util.Properties;
import java.util.StringTokenizer;
import java.util.Vector;

import lotus.domino.Database;
import lotus.domino.DateTime;
import lotus.domino.Document;
import lotus.domino.DocumentCollection;
import lotus.domino.EmbeddedObject;
import lotus.domino.Name;
import lotus.domino.RichTextItem;
import clenotes.CLENotesSession;
import clenotes.Configuration;

public class CLUI {
	private static String xMailer = Configuration.MAILER;

	private String userName;
	private String commonUserName;

	private int numberOfDocuments = 0;

	private lotus.domino.Session notesSession;
	private Database mailDatabase;

	private BufferedReader stdin = new BufferedReader(new InputStreamReader(
			System.in));

	private String smtpHost;//="9.52.27.158";//"9.52.27.142";
	private String notesMailServer;//="D17ML402/17/M/IBM";
	private String localMailDatabase;//="Fi722150.nsf";
	private String userEmailAddress;//="sami.salkosuo@fi.ibm.com";
	private String signature = "Regards";
	private boolean useSignature;
	private String signatureFile;
	private int maxMailsPerScreen=5;
	private boolean showSmtpCommunication;//=true;
	private int charsPerScreen;//=256;
	private boolean useLocalMailDatabase;//=true;

	private Properties mailProperties = new Properties();

	private String shutdownText = "Thank you for using " + xMailer + ".";//\nProvided by Sami Salkosuo/Mobile Partner Innovation Center,IBM EMEA.";

	public CLUI() {

	}

	public void setUserEmailAddress(String emailAddress) {
		userEmailAddress = emailAddress;
	}

	public void setSmtpServer(String smtpServer) {
		smtpHost = smtpServer;
		mailProperties.setProperty("mail.smtp.host", smtpHost);
	}

	public void execute() {
		try {
			STDOUT("Welcome to " + xMailer + ".");
			STDOUT("For help type 'help' or 'h'.");

			notesSession = CLENotesSession.getSession();
			mailDatabase = CLENotesSession.getMailDatabase();

			userName = notesSession.getUserName();
			commonUserName = notesSession.getCommonUserName();
			Name name = notesSession.getUserNameObject();

			//get document count
			DocumentCollection dc = mailDatabase.search("From!=\"" + userName + "\"");//db.getAllDocuments();
			numberOfDocuments = dc.getCount();
			dc.recycle();
			String input = null;
			STDOUT("maildatabase>", false);
			while (!(input = STDIN()).equalsIgnoreCase("exit")
					&& !input.equalsIgnoreCase("x")) {
				try {
					String command = "";
					StringTokenizer st = new StringTokenizer(input, " ");
					if (st.hasMoreTokens()) {
						command = st.nextToken().toLowerCase();
					}

					if (command.equals("read") || command.equals("r")) {
						readCommand(st);
					}

					if (useLocalMailDatabase
							&& (command.equals("replicate") || command.equals("re"))) {
						//replicate
						replicate();
					}

					if (command.equals("info") || command.equals("i")) {
						infoCommand(st);
					}
/*
					if (command.equals("check") || command.equals("c")) {
						checkCommand(st);
					}
*/
					if (command.equals("list") || command.equals("l")) {
						listCommand(st);
					}

					if (command.equals("search") || command.equals("s")) {
						searchCommand(st);
					}
/*
					if (command.equals("mail") || command.equals("m")) {
						mailCommand(st);
					}
*/
					if (command.equals("today") || command.equals("t")) {
						todayCommand(st);
					}

					if (command.equals("help") || command.equals("h")) {
						helpCommand();
					}

				} catch (Exception e) {
					e.printStackTrace();
				}
				STDOUT("maildatabase>", false);
			}
			notesSession.recycle();
			STDOUT(shutdownText);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private void replicate() throws Exception {
		if (mailDatabase.isOpen()) {
			String title = mailDatabase.getTitle();
			STDOUT("Replicating.. \"" + title + "\"");
			if (mailDatabase.replicate(notesMailServer)) {
				STDOUT("\"" + title + "\" has replicated.");
			} else
				STDOUT("Error replicating \"" + title + "\".");
		}
	}

	private void helpCommand() {
		/*     StringBuffer sb=new StringBuffer();
		 *     sb.append("<?xml version=\"1.0\"?>\n");
		 */

		STDOUT(xMailer);
		STDOUT("Mail database of " + userName + ".");
		STDOUT("Commands:");
//		STDOUT("\tcheck (c) - Check new mail.");
		STDOUT("\thelp (h) - This help.");
		STDOUT("\tinfo (i) - Information about mail database.");
		STDOUT("\tlist (l) [[<start index> &&] <end index>] - List mail. ");
//		STDOUT("\tmail (m) - Send mail.");
		STDOUT("\tread (r) [<mail index>] - Read mail.");
		if (useLocalMailDatabase) STDOUT("\treplicate (re) - Replicate mail.");
		STDOUT("\tsearch (s) - Search mail.");
		STDOUT("\ttoday (t) - List today's mail.");//list mails that are replicated today
		STDOUT("\texit (x) - Exit program.");
		STDOUT();
		//STDOUT("This is "+xMailer);
		//STDOUT("Provided by Sami Salkosuo/Mobile Partner Innovation Center,IBM EMEA.");

	}

	private void searchCommand(StringTokenizer params) throws Exception {
		//DateTime sinceDate=null;

		//sinceDate=notesSession.createDateTime("yesterday");

		String formula = "";
		String input;
		String searchString = "";
		//cli for search
		STDOUT("search>", false);

		while (!(input = STDIN()).equalsIgnoreCase("exit")
				&& !input.equalsIgnoreCase("x")) {
			try {
				StringTokenizer st = new StringTokenizer(input, " ");
				String command = "";
				if (st.hasMoreTokens()) {
					command = st.nextToken().toLowerCase();
				}

				//search commands
				if (command.equals("body") || command.equals("b")) {
					if (st.hasMoreElements()) {
						while (st.hasMoreTokens()) {
							searchString += " " + st.nextToken();
						}
						//formula="@Contains(Body;\""+searchString+"\")";
						formula = "FULLTEXT";
						searchResults(formula, searchString);
					} else {
						STDOUT("Search string missing.");
					} // end of else

					//@Contains(Subject;"PBC") & !@Contains(From;"Salkosuo")
				}

				if (command.equals("formula")) {
					while (st.hasMoreTokens()) {
						formula += " " + st.nextToken();
					}
					searchResults(formula, searchString);
				}

				if (command.equals("from") || command.equals("f")) {
					if (st.hasMoreElements()) {
						searchString = st.nextToken();
						formula = "@Contains(From;\"" + searchString + "\")";
						searchResults(formula, searchString);
					} else {
						STDOUT("Search string missing.");
					} // end of else

					//@Contains(Subject;"PBC") & !@Contains(From;"Salkosuo")
				}
				if (command.equals("subject") || command.equals("s")) {
					if (st.hasMoreElements()) {
						searchString = st.nextToken();
						formula = "@Contains(Subject;\"" + searchString + "\")";
						searchResults(formula, searchString);
					} else {
						STDOUT("Search string missing.");
					} // end of else

				}

				if (command.equals("help") || command.equals("h")) {
					STDOUT("Commands: ");
					STDOUT("\tbody (b) <case sensitive search string> - Full text search.");
					//STDOUT("\tformula <formula> - search by formula (@Contains($Mailer;\"Lotus\") & @Contains(Subject;\"Lotus\"))");
					STDOUT("\tformula <formula> - Search by formula.");
					STDOUT("\tfrom (f) <case sensitive search string> - Search sender.");
					STDOUT("\tsubject (s) <case sensitive search string> - Search from subject.");
					STDOUT("\texit (x)");
				}

			} catch (Exception e) {
				e.printStackTrace();
			} // end of try-catch
			STDOUT("search>", false);
		}

	}

	private void searchResults(String formula, String searchString)
			throws Exception {
		int startDoc = 0;
		int endDoc = -1;
		DocumentCollection dc;
		if (formula.equals("FULLTEXT")) {
			dc = mailDatabase.FTSearch(searchString);
		} // end of if ()
		else {
			dc = mailDatabase.search(formula);
		} // end of else

		//DocumentCollection dc = mailDatabase.search(formula);
		STDOUT("Found " + dc.getCount() + " documents.");
		String receivedMail = getMail(dc, startDoc, endDoc, true);
		printReceivedMail(receivedMail, startDoc);

		//search results
		STDOUT("searchresults>", false);
		String input;
		while (!(input = STDIN()).equalsIgnoreCase("exit")
				&& !input.equalsIgnoreCase("x")) {
			StringTokenizer st = new StringTokenizer(input, " ");
			String command = "";
			if (st.hasMoreTokens()) {
				command = st.nextToken().toLowerCase();
			}
			if (command.equals("list") || command.equals("l")) {
				/* 	    DocumentCollection dc = mailDatabase.search(formula);
				 * 	    STDOUT("Found "+dc.getCount()+" documents.");
				 * 	    String receivedMail=getMail(dc,startDoc,endDoc,true);
				 */
				printReceivedMail(receivedMail, startDoc);
			}
			if (command.equals("read") || command.equals("r")) {
				if (readCommand(st, formula, searchString)) {
					//document deleted read mail again
					receivedMail = getMail(dc, startDoc, endDoc, true);
				} // end of if ()

			}
			if (command.equals("help") || command.equals("h")) {
				STDOUT("Commands: ");
				STDOUT("\tlist (l) - List search results..");
				STDOUT("\tread (r) [<mail index>] - Read mail from search results.");
				STDOUT("\texit (x)");
			}
			STDOUT("searchresults>", false);
		}
		STDOUT();
		dc.recycle();
	}

	private void mailCommand(StringTokenizer params) throws Exception {
		
		STDOUT("Mail command not yet implemented.");
		return;
/*		try {
			String input;
			String signatureFile = null;
			if (params.hasMoreTokens()) {
				signatureFile = params.nextToken();
			} // end of if ()

			STDOUT("Send new mail. Enter 'Q' to cancel.");
			STDOUT("From : " + userEmailAddress);

			MimeMessage message = initSendMail();

			if (addTo(message).equals("Q") || addCc(message).equals("Q")
					|| addBcc(message).equals("Q") || setSubject(message).equals("Q")) {
				return;
			} // end of if ()

			Multipart multipart = addBody(signatureFile);

			if (addAttachments(multipart).equals("Q")) {
				return;
			} // end of if ()
			sendMail(multipart, message);

		} catch (Exception e) {
			e.printStackTrace();
		}
	*/
	}

	/*
	private MimeMessage initSendMail() throws Exception {
		//javax mail
		javax.mail.Session session = javax.mail.Session.getInstance(mailProperties,
				null);
		session.setDebug(showSmtpCommunication);
		// Define message
		MimeMessage message = new MimeMessage(session);
		message.setFrom(new InternetAddress(userEmailAddress));
		return message;
	}

	private void sendMail(Multipart multipart, MimeMessage message)
			throws Exception {
		// Put parts in message
		message.setContent(multipart);
		message.addHeader("X-Mailer", xMailer);
		message.setSentDate(new Date());
		// Send the message
		Transport.send(message);
		STDOUT("Mail sent.");

	}

	private String addAttachments(Multipart multipart) throws Exception {
		String input;
		STDOUT("Add attachment file name(s), hit ENTER to finish.");
		STDOUT("Attachment file name? ", false);
		while (!(input = STDIN()).equals("") && !input.equals("Q")) {
			if ((new File(input)).exists()) {
				MimeBodyPart messageBodyPart = new MimeBodyPart();
				DataSource source = new FileDataSource(input);
				messageBodyPart.setDataHandler(new DataHandler(source));
				if (input.lastIndexOf("/") > -1) {
					input = input.substring(input.lastIndexOf("/") + 1);
				} // end of if ()
				if (input.lastIndexOf("\\") > -1) {
					input = input.substring(input.lastIndexOf("\\") + 1);
				} // end of if ()

				messageBodyPart.setFileName(input);
				multipart.addBodyPart(messageBodyPart);
			} // end of if ()
			else {
				STDOUT("File does not exist.");
			} // end of else
			STDOUT("Attachment file name? ", false);
		}
		return input;
	}

	private String addTo(MimeMessage message) throws Exception {
		String input;
		STDOUT("Add recipient(s), hit ENTER to finish.");
		STDOUT("To: ", false);
		while (!(input = STDIN()).equals("") && !input.equals("Q")) {
			message
					.addRecipient(Message.RecipientType.TO, new InternetAddress(input));
			STDOUT("To: ", false);
		}
		return input;
	}

	private String addCc(MimeMessage message) throws Exception {
		String input;
		STDOUT("Add cc, hit ENTER to finish.");
		STDOUT("Cc: ", false);
		while (!(input = STDIN()).equals("") && !input.equals("Q")) {
			message
					.addRecipient(Message.RecipientType.CC, new InternetAddress(input));
			STDOUT("Cc: ", false);
		}
		return input;
	}

	private String addBcc(MimeMessage message) throws Exception {
		String input;
		STDOUT("Add bcc, hit ENTER to finish.");
		STDOUT("Bcc: ", false);
		while (!(input = STDIN()).equals("") && !input.equals("Q")) {
			message.addRecipient(Message.RecipientType.BCC,
					new InternetAddress(input));
			STDOUT("Bcc: ", false);
		}
		return input;
	}

	private String setSubject(MimeMessage message) throws Exception {
		STDOUT("Subject: ", false);
		String input = STDIN();
		message.setSubject(input);
		return input;
	}

	private Multipart addBody(String signatureFile) throws Exception {
		String input;
		STDOUT("Body of the message, type 'exit' to finish message.");
		StringBuffer sb = new StringBuffer();
		while (!(input = STDIN()).equalsIgnoreCase("exit")) {
			sb.append(input);
			sb.append('\n');
		}
		sb.append('\n');

		//add signature from file
		if (useSignature) {
			if (signatureFile == null) {
				signatureFile = this.signatureFile;
			} // end of if ()

			File sFile = new File(signatureFile);
			if (sFile.exists()) {
				BufferedReader reader = new BufferedReader(new InputStreamReader(
						new FileInputStream(sFile)));
				String sigInput;
				while ((sigInput = reader.readLine()) != null) {
					sb.append(sigInput);
					sb.append('\n');
				} // end of while ()
				reader.close();
			} // end of if ()

		} // end of if ()

		// create the message part
		MimeBodyPart messageBodyPart = new MimeBodyPart();
		//fill message
		messageBodyPart.setText(sb.toString());
		Multipart multipart = new MimeMultipart();
		multipart.addBodyPart(messageBodyPart);
		return multipart;
	}
*/
	
	private void todayCommand(StringTokenizer params) throws Exception {
		int startDoc = 0;
		int endDoc = -1;
		DateTime sinceDate = null;

		sinceDate = notesSession.createDateTime("yesterday");
		switch (params.countTokens()) {
		case 0:
			break;
		case 1:
			String param = params.nextToken();
			try {
				sinceDate.adjustDay(-(Math.abs(Integer.parseInt(param))));
			} catch (Exception e) {
			}
			break;
		default:
		}
		DocumentCollection dc = mailDatabase.search("From !=\"" + userName + "\"",
				sinceDate);
		//numberOfDocuments=dc.getCount();
		String receivedMail = getMail(dc, startDoc, endDoc, true);
		dc.recycle();
		printReceivedMail(receivedMail, startDoc);

	}

	private void infoCommand(StringTokenizer params) throws Exception {
		DocumentCollection dc = mailDatabase.getAllDocuments();
		STDOUT("Mail database : " + mailDatabase.getTitle());
		STDOUT("Server: " + mailDatabase.getServer());
		STDOUT("Path: " + mailDatabase.getFilePath());
		STDOUT("Name: " + mailDatabase.getFileName());
		STDOUT("Size: " + ((int) (mailDatabase.getSize() / 1024)) + "KB");
		STDOUT("Documents: " + dc.getCount());
		dc = mailDatabase.search("From!=\"" + userName + "\"");//mailDatabase.getAllDocuments();
		STDOUT("Received email: " + dc.getCount());
		dc.recycle();
	}

	private boolean readCommand(StringTokenizer params) throws Exception {
		return readCommand(params, "From !=\"" + userName + "\"", null);
	}

	private boolean readCommand(StringTokenizer params, String formula,
			String searchString) throws Exception {
		int startDoc = 0;
		int endDoc = 0;
		String param;
		switch (params.countTokens()) {
		case 0:
			startDoc = 0;
			break;
		case 1:
			param = params.nextToken();
			startDoc = Integer.parseInt(param);
			break;
		default:
			STDOUT("Too many arguments.");
			return false;
		}
		endDoc = startDoc;
		DocumentCollection dc;
		if (formula.equals("FULLTEXT")) {
			dc = mailDatabase.FTSearch(searchString);
		} // end of if ()
		else {
			dc = mailDatabase.search(formula);
		} // end of else
		//DocumentCollection dc = mailDatabase.search(formula);//mailDatabase.search("From !=\""+userName+"\"");
		String mail = getMail(dc, startDoc, endDoc, false);

		//new prompr for readin mail
		String input = null;
		printMail(mail, true);
		//String from=getTagValue(mail,"from");
		//System.out.print("mail from "+from+">");
		STDOUT("mail>", false);
		while (!(input = STDIN()).equalsIgnoreCase("exit")
				&& !input.equalsIgnoreCase("x")) {
			String command = "";
			StringTokenizer st = new StringTokenizer(input, " ");
			if (st.hasMoreTokens()) {
				command = st.nextToken().toLowerCase();
			}
			try {
				if (command.equals("delete") || command.equals("d")) {
					STDOUT("Delete mail, are you sure (yes/no)? ", false);
					if (STDIN().equals("yes")) {
						//delete mail
						boolean success = deleteDocument(dc, startDoc);
						STDOUT("Delete successful: " + success);
						if (success) {
							numberOfDocuments--;
						} // end of if ()
						dc.recycle();
						return success;
					} // end of if ()
				}
				if (command.equals("info") || command.equals("i")) {
					printMail(mail, false, true);
				}

				if (command.equals("open") || command.equals("o")) {
					printMail(mail, true);
				}

				if (command.equals("reply") || command.equals("r")) {
					replyMail(mail);
				}

				if (command.equals("forward") || command.equals("f")) {
					forwardMail(mail);
				}

				if (command.equals("attachment") || command.equals("a")) {
					attachmentCommand(startDoc);
				}

				if (command.equals("help") || command.equals("h")) {
					STDOUT("Commands: ");
					STDOUT("\tattachment (a)");//get attachment
					STDOUT("\tdelete (d)");
					STDOUT("\tforward (f)");
					STDOUT("\thelp (h)");
					STDOUT("\tinfo (i)");
					STDOUT("\topen (o)");
					STDOUT("\treply (r)");
					STDOUT("\texit (x)");
				}
			} catch (Exception e) {
				e.printStackTrace();
			} // end of try-catch
			STDOUT("mail>", false);
		}
		dc.recycle();
		return false;
	}

	private void replyMail(String mailXml) throws Exception {
		STDOUT("Reply mail not yet implemented.");
		return;
		/*
		//reply mail
		//copy mail to reply
		//add to, cc, bcc, subject is RE: subject
		String mail = getTagValue(mailXml, "mail");
		String from = getTagValue(mail, "from");
		String to = getTagValue(mail, "replyto");
		if (to.equals("null")) {
			to = getTagValue(mail, "inetfrom");
			if (to.equals("null")) {
				Name name = notesSession.createName(from);
				to = name.getAddr821();
				name.recycle();
				//to=from;
			} // end of if ()
		} // end of if ()

		String subject = getTagValue(mail, "subject");
		STDOUT("Reply to " + from + ".");
		STDOUT("Enter 'Q' to cancel.");
		STDOUT("From : " + userEmailAddress);
		STDOUT("To : " + to);

		MimeMessage message = initSendMail();
		message.addRecipient(Message.RecipientType.TO, new InternetAddress(to));
		if (addTo(message).equals("Q") || addCc(message).equals("Q")
				|| addBcc(message).equals("Q")) {
			return;
		} // end of if ()
		STDOUT("Subject: RE: " + subject);
		message.setSubject("RE: " + subject);
		STDOUT("Include mail to reply? ", false);
		String input = STDIN().toLowerCase();
		StringBuffer sb = new StringBuffer(signature);
		if (input.equals("yes") || input.equals("y")) {
			sb.append("\n\n");
			sb.append("On ");
			sb.append(getTagValue(mail, "date"));
			sb.append(" ");
			sb.append(getTagValue(mail, "time"));
			sb.append("\n");
			sb.append(to);
			sb.append(" wrote:\n\n");
			sb.append(getTagValue(mail, "body"));
		}
		Multipart multipart = addBody(sb.toString());
		if (addAttachments(multipart).equals("Q")) {
			return;
		} // end of if ()

		sendMail(multipart, message);
		*/
	}

	private void forwardMail(String mailXml) throws Exception {
		STDOUT("Forward mail not yet implemented.");
		return;
		/*
		//reply mail
		//copy mail to reply
		//add to, cc, bcc, subject is RE: subject
		String mail = getTagValue(mailXml, "mail");
		String to = getTagValue(mail, "from");
		String subject = getTagValue(mail, "subject");
		STDOUT("Forward mail.");
		STDOUT("From : " + userEmailAddress);
		MimeMessage message = initSendMail();
		addTo(message);
		addCc(message);
		addBcc(message);
		STDOUT("Subject: FWD: " + subject);
		message.setSubject("FWD: " + subject);
		StringBuffer sb = new StringBuffer(signature);
		sb.append("\n\n");
		sb.append("On ");
		sb.append(getTagValue(mail, "date"));
		sb.append(" ");
		sb.append(getTagValue(mail, "time"));
		sb.append("\n");
		sb.append(to);
		sb.append(" wrote:\n\n");
		sb.append(getTagValue(mail, "body"));

		Multipart multipart = addBody(sb.toString());
		addAttachments(multipart);
		sendMail(multipart, message);
		*/
	}

	private void attachmentCommand(int docIndex) throws Exception {
		Document doc = getDocument(docIndex);
		String dir = System.getProperty("user.dir");
		Object obj = doc.getFirstItem("Body");
		if (obj == null) {
			obj = doc.getFirstItem("$Body");
		}
		if (obj instanceof RichTextItem) {
			RichTextItem body = (RichTextItem) obj;
			Vector<?> v = body.getEmbeddedObjects();
			if (v.size() == 0) {
				STDOUT("No attachments.");
			} // end of if ()
			else {
				Enumeration<?> e = v.elements();
				while (e.hasMoreElements()) {
					EmbeddedObject eo = (EmbeddedObject) e.nextElement();
					if (eo.getType() == EmbeddedObject.EMBED_ATTACHMENT) {
						STDOUT("Detach " + eo.getName() + "(" + eo.getFileSize()
								+ ") to directory " + dir + " (yes/no)? ", false);
						String input = STDIN().toLowerCase();
						if (input.equals("yes") || input.equals("y")) {
							detachFile(dir, eo);
						} // end of if ()
						if (input.equals("no") || input.equals("n")) {
							STDOUT("Enter new directory: ", false);
							input = STDIN().toLowerCase();
							detachFile(input, eo);
						}
					}
				}
			} // end of else
		} else {
			STDOUT("No attachments.");
		} // end of else

	}

	private void detachFile(String dir, EmbeddedObject eo) throws Exception {
		if (dir.equals("") || dir.equals("Q")) {
			return;
		} // end of if ()

		dir = dir.replace('\\', '/');
		if (!dir.endsWith("/")) {
			dir += "/";
		} // end of if ()
		eo.extractFile(dir + eo.getSource());
		STDOUT("File detached.");
		//eo.remove();
	}

	private boolean deleteDocument(DocumentCollection dc, int docIndex)
			throws Exception {
		int count = dc.getCount();
		return dc.getNthDocument(count - docIndex).remove(true);
	}

	private String listCommand(StringTokenizer params) throws Exception {
		int startDoc = 0;
		int endDoc = 1;
		String param;

		switch (params.countTokens()) {
		case 0:
			startDoc = 0;
			endDoc = 0;
			break;

		case 1:
			param = params.nextToken();
			startDoc = 0;
			endDoc = Math.abs(Integer.parseInt(param)) - 1;
			if (endDoc < 0) {
				endDoc = 0;
			} // end of if ()

			break;

		case 2:
			param = params.nextToken();
			startDoc = Math.abs(Integer.parseInt(param));
			param = params.nextToken();
			endDoc = Math.abs(Integer.parseInt(param));
			break;
		default:
			STDOUT("Too many arguments.");
			return "";
		}

		DocumentCollection dc = mailDatabase.search("From !=\"" + userName + "\"");
		numberOfDocuments = dc.getCount();
		String receivedMail = getMail(dc, startDoc, endDoc, true);
		dc.recycle();
		printReceivedMail(receivedMail, startDoc);

		return receivedMail;
	}

	private void checkCommand(StringTokenizer params) throws Exception {

		DocumentCollection dc = mailDatabase.search("From !=\"" + userName + "\"");
		if (dc.getCount() > numberOfDocuments) {
			STDOUT("You have " + (dc.getCount() - numberOfDocuments)
					+ " new mail(s).");
			numberOfDocuments = dc.getCount();
		} // end of if ()
		if (dc.getCount() < numberOfDocuments) {
			numberOfDocuments = dc.getCount();
		}
		dc.recycle();
	}

	private String getMail(DocumentCollection dc, int startDoc, int endDoc,
			boolean brief) throws Exception {
		boolean allDocs = false;
		int numberOfReceivedMail;

		int count = dc.getCount();
		if (endDoc == -1) {
			numberOfReceivedMail = count;
			endDoc = count;
			allDocs = true;
		} // end of if ()
		else {
			numberOfReceivedMail = endDoc - startDoc + 1;
		} // end of else

		StringBuffer sb = new StringBuffer();
		sb.append("<?xml version=\"1.0\"?>\n<receivedMail total=\"");
		sb.append(numberOfReceivedMail);
		sb.append("\">\n");

		if (allDocs) {
			Document doc = dc.getLastDocument();
			while (doc != null) {
				getMailContent(sb, doc, brief);
				doc = dc.getPrevDocument();
			} // end of while ()
		} else {
			for (int i = startDoc; i <= endDoc; i++) {
				Document doc = dc.getNthDocument(count - i);
				getMailContent(sb, doc, brief);
			}
		}

		sb.append("</receivedMail>");
		return sb.toString();
	}

	private Document getDocument(int docIndex) throws Exception {
		DocumentCollection dc = mailDatabase.search("From !=\"" + userName + "\"");
		int count = dc.getCount();
		return dc.getNthDocument(count - docIndex);
	}

	private void getMailContent(StringBuffer sb, Document doc, boolean brief)
			throws Exception {

		sb.append("<mail>");

		sb.append(getDeliveryTime(doc));

		sb.append("<from>");
		String from = doc.getItemValueString("From");
		sb.append(from);
		sb.append("</from>\n");
		sb.append("<inetfrom>");
		String inetfrom = doc.getItemValueString("INetFrom");
		if (inetfrom == null) {
			sb.append("null");
		} // end of if ()
		else {
			sb.append(inetfrom);
		} // end of else
		sb.append("</inetfrom>\n");
		sb.append("<replyto>");
		String replyTo = doc.getItemValueString("ReplyTo");
		if (replyTo == null) {
			sb.append("null");
		} // end of if ()
		else {
			sb.append(replyTo);
		} // end of else

		sb.append("</replyto>\n");
		sb.append("<importance>");
		String value = doc.getItemValueString("Importance");
		if (value == null) {
			sb.append("Normal");
		} // end of if ()
		else {
			if (value.equals("3")) {
				sb.append("FYI");
			} else {
				sb.append("Urgent");
			}

		} // end of else
		sb.append("</importance>\n");

		sb.append("<subject>");
		sb.append(doc.getItemValueString("Subject"));
		sb.append("</subject>\n");

		//attachments
		sb.append("<attachments>\n");

		Object obj = doc.getFirstItem("Body");
		boolean bodyIsNull = false;
		if (obj == null) {
			bodyIsNull = true;
			obj = doc.getFirstItem("$Body");
		}
		if (obj instanceof RichTextItem) {
			RichTextItem body = (RichTextItem) obj;
			Vector<?> v = body.getEmbeddedObjects();
			Enumeration<?> e = v.elements();
			while (e.hasMoreElements()) {
				EmbeddedObject eo = (EmbeddedObject) e.nextElement();
				switch (eo.getType()) {
				case EmbeddedObject.EMBED_ATTACHMENT:
					sb.append("<file>");
					sb.append("<name>");
					sb.append(eo.getName());
					sb.append("</name>");
					sb.append("<size>");
					sb.append(eo.getFileSize());
					sb.append("</size>");
					sb.append("</file>\n");
					break;
				case EmbeddedObject.EMBED_OBJECT:
				case EmbeddedObject.EMBED_OBJECTLINK:
					break;
				}
			}
		} // end of if ()

		sb.append("</attachments>\n");

		if (!brief) {
			//sb.append(getItemList("INetSendTo","inetTo",doc));
			sb.append(getItemList("SendTo", "to", doc));
			sb.append(getItemList("CopyTo", "cc", doc));
			sb.append(getItemList("BlindCopyTo", "bcc", doc));
			sb.append("<mailer>");
			sb.append(doc.getItemValueString("$Mailer"));
			sb.append("</mailer>\n");
			sb.append("<messageid>");
			sb.append(doc.getItemValueString("$MessageID"));
			sb.append("</messageid>\n");

			sb.append("<body>");
			if (bodyIsNull) {
				sb.append(doc.getItemValueString("$Body"));
			} // end of if ()
			else {
				sb.append(doc.getItemValueString("Body"));
			} // end of else
			sb.append("</body>\n");

		} // end of if ()
		sb.append("</mail>\n");
		//i++;
	}

	private String getItemList(String fieldName, String xmlName, Document doc)
			throws Exception {
		Vector<?> vr = doc.getItemValue(fieldName);
		StringBuffer sb = new StringBuffer();
		sb.append("<");
		sb.append(xmlName);
		sb.append(" total=\"");
		sb.append(vr.size());
		sb.append("\">");
		for (int i = 0; i < vr.size(); i++) {
			sb.append("<item>");
			sb.append((String) vr.elementAt(i));
			sb.append("</item>");
		} // end of for ()
		sb.append("</");
		sb.append(xmlName);
		sb.append(">");
		return sb.toString();
	}

	private String getDeliveryTime(Document doc) throws Exception {
		StringBuffer sb = new StringBuffer();
		String arr[] = { "FollowUpTime", "DeliveredDate", "PostedDate" };
		int i = 0;
		Vector<?> vr;
		do {
			vr = doc.getItemValue(arr[i]);
			i++;
		} while (vr.size() == 0);

		DateTime dt = (DateTime) vr.firstElement();
		sb.append("<date>");
		sb.append(dt.getDateOnly());
		sb.append("</date>\n");
		sb.append("<time>");
		sb.append(dt.getTimeOnly());
		sb.append("</time>\n");
		sb.append("<gmt>");
		sb.append(dt.getGMTTime());
		sb.append("</gmt>\n");

		return sb.toString();
	}

	private void printReceivedMail(String receivedMail, int startDoc)
			throws Exception {
		String mail = getTagValue(receivedMail, "mail");
		STDOUT("Displaying " + getTotalAttribute(receivedMail) + " emails.");
		int i = startDoc;
		int j = 0;
		while (mail != null) {
			receivedMail = receivedMail
					.substring(receivedMail.indexOf("</mail>") + 6);
			STDOUT("[" + i + "] " + getTagValue(mail, "date") + " ", false);
			STDOUT(getTagValue(mail, "time"));
			STDOUT("\tFrom: " + getTagValue(mail, "from"));
			STDOUT("\tSubject: " + getTagValue(mail, "subject"));
			String attachments = getTagValue(mail, "attachments");
			String file = getTagValue(attachments, "file");
			STDOUT("\tAttachments: ", false);
			while (file != null) {
				attachments = attachments.substring(attachments.indexOf("</file>") + 5);
				STDOUT(getTagValue(file, "name") + "(" + getTagValue(file, "size")
						+ ");", false);
				file = getTagValue(attachments, "file");
			} // end of while ()
			STDOUT("\n");
			mail = getTagValue(receivedMail, "mail");
			i++;
			j++;
			if (j > maxMailsPerScreen) {
				STDOUT("More...?", false);
				String input = STDIN().toLowerCase();
				if (input.equals("no") || input.equals("n")) {
					return;
				} // end of if ()
				j = 0;
			} // end of if ()

		} // end of while ()

	}

	private void printMail(String mailXml, boolean printBody) throws Exception {
		printMail(mailXml, printBody, false);
	}

	private void printMail(String mailXml, boolean printBody, boolean hidden)
			throws Exception {
		String input;
		String mail = getTagValue(mailXml, "mail");
		STDOUT("Date: " + getTagValue(mail, "date") + " ", false);
		STDOUT(getTagValue(mail, "time"));
		STDOUT("From: " + getTagValue(mail, "from"));
		STDOUT("Reply to: " + getTagValue(mail, "replyto"));
		STDOUT("Subject: " + getTagValue(mail, "subject"));
		STDOUT("To: ", false);
		printItems(getTagValue(mail, "to"), "to");
		STDOUT("Cc: ", false);
		printItems(getTagValue(mail, "cc"), "cc");
		STDOUT("Importance: " + getTagValue(mail, "importance"));
		if (hidden) {
			STDOUT("Mailer: " + getTagValue(mail, "mailer"));
			STDOUT("MessageID: " + getTagValue(mail, "messageid"));
		} // end of if ()

		STDOUT("Attachments: ", false);
		String attachments = getTagValue(mail, "attachments");
		String file = getTagValue(attachments, "file");
		//STDOUT("\tAttachments: ");
		while (file != null) {
			attachments = attachments.substring(attachments.indexOf("</file>") + 5);
			STDOUT(
					getTagValue(file, "name") + "(" + getTagValue(file, "size") + ");",
					false);
			file = getTagValue(attachments, "file");
		} // end of while ()
		if (printBody) {
			//STDOUT("\n\nBody:");
			STDOUT();
			STDOUT("--- MAIL BODY ---");

			String body = getTagValue(mail, "body");

			StringReader reader = new StringReader(body);
			//print body, n lines per screen
			char[] bodyArray = new char[charsPerScreen];
			int bytesRead = 0;
			while ((bytesRead = reader.read(bodyArray, 0, charsPerScreen)) > -1) {
				STDOUT(new String(bodyArray, 0, bytesRead));
				STDOUT("More...?", false);
				input = STDIN().toLowerCase();
				if (input.equals("no") || input.equals("n")) {
					return;
				} // end of if ()
			} // end of while ()
			reader.close();
		} else {
			STDOUT();
		} // end of else
	}

	private void printItems(String items, String tagName) {
		String item = getTagValue(items, "item");
		//STDOUT("\tAttachments: ");
		while (item != null) {
			items = items.substring(items.indexOf("</item>") + 5);
			STDOUT(item + ";", false);
			item = getTagValue(items, "item");
		} // end of while ()
		STDOUT();
	}

	private String getTagValue(String xmlString, String tagName) {
		try {
			int index = xmlString.indexOf("<" + tagName + ">");
			if (index == -1) {
				index = xmlString.indexOf("<" + tagName + " ");
			} // end of if ()

			int tagLength = index + 2 + tagName.length();

			return xmlString.substring(tagLength,
					xmlString.indexOf("</" + tagName + ">"));

		} catch (StringIndexOutOfBoundsException e) {
			return null;
		} // end of try-catch
	}

	private String getTotalAttribute(String xml) {
		try {
			int index = xml.indexOf("total=");
			return xml.substring(index + 7, xml.indexOf("\"", index + 7));

		} catch (StringIndexOutOfBoundsException e) {
			return null;
		} // end of try-catch

	}

	private String STDIN() throws Exception {
		String line = stdin.readLine();
		if (line == null) {
			STDOUT();
			return "";
		} // end of if ()
		return line;

	}

	private void STDOUT() {
		STDOUT("", true);
	}

	private void STDOUT(String string) {
		STDOUT(string, true);
	}

	private void STDOUT(String string, boolean lineFeed) {
		if (lineFeed) {

			System.out.println(string);
		} // end of if ()
		else {
			System.out.print(string);
		} // end of else
	}

}
