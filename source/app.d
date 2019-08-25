//#buggy?
//#I don't see "n" doing any thing?!
//#upto with history
import std.stdio;
import std.string;
import std.array: split, replace;
import std.file;
import std.conv;
import std.process;
import std.range;
import std.datetime;

import dunit;
import dlangui;

import arsd.dom: Document, Element;

import bible.base, jmisc;

version = retinaDisplay;

const SCALE_FACTOR = 2.0f;

immutable g_editBoxsWrapWidth = 36;

mixin APP_ENTRY_POINT;

class TestUnitTest {
	mixin UnitTest;

	@Test
	void tfail() {
		assert(false);
	}

	@Test
	void tpass() {
		assert(true);
	}

    @Test
    void assertEqualsFailure()
    {
        string expected = "bar";
        string actual = "baz";

        assertEquals(expected, actual);
    }
}

// production
struct MainWindow {
	Window _window;
	EditBox _editBoxMain,
		_editBoxRight,
		_editBoxHistory;
	EditLine _editLineInWindowSpot,
		_editLineSearch,
		_editLineTitle,
		_editLineTitleAndSubTitle;
	CheckBox _checkBoxSearchCaseSensitive,
		_checkBoxPartWordSearch,
		_checkBoxWordSearch,
		_checkBoxPhraseSearch,
		_checkBoxAppend;
	Button _wrapToggle;

	string _input;
	bool _done = false, _doVerse;

	string _helpTxt;

	int setup() {
		_helpTxt = readText("help.txt");

		version(none)
			dunit_main(dargs);

		//#stuff at the start (in the terminal when the the program is run)
		immutable BIBLE_VER = "esv"; // "jkv";
		loadBible(BIBLE_VER);

		g_wrap = false;


		_window = Platform.instance.createWindow(
			"Jyble Bible", null, WindowFlag.Resizable, 780 + 12, 800);
		
		// Crease widget to show in window
		_window.mainWidget = parseML(q{
			VerticalLayout {
				backgroundColor: "#80FF00"
				textColor: "#000000"
				margins: 3
				padding: 3

				HorizontalLayout {
					EditBox {
						id: editBoxMain
						minWidth: 786; minHeight: 1000; maxHeight: 1000;
					}
					EditBox {
						id: editBoxRight
						minWidth: 786; minHeight: 1000; maxHeight: 1000;
					}
				}

				TextWidget {
					text: "History:";
				}
				EditBox {
					id: editBoxHistory
					minWidth: 1400; minHeight: 320; maxHeight: 320;
				}

				HorizontalLayout {
					TextWidget {
						text: "Enter command:"
					}
					EditLine {
						id: editLineInWindowSpot
						minWidth: 800
					}
					Button {
						id: buttonActivate
						text: "Activate"
					}
					Button { id: buttonWrap; text: "*Wrap Text" }
					Button {
						id: buttonExpVers
						text: "Expand Verses"
					}
				}
				
				HorizontalLayout {
					Button { id: buttonClearLeft; text: "Clear left" }
					TextWidget {
						text: "Search:"
					}
					EditLine {
						id: editLineSearch
						minWidth: 400
					}
					TextWidget { text: "pws-" }
					CheckBox { id: checkBoxPartWordSearch; }
					TextWidget { text: "ws-" }
					CheckBox { id: checkBoxWordSearch; }
					TextWidget { text: "ps-" }
					CheckBox { id: checkBoxPhraseSearch; }
					TextWidget {
						text: "case-"
					}					
					CheckBox { id: checkBoxSearchCaseSensitive; }
					Button {
						id: buttonActivateSearch
						text: "Activate Search"
					}
					Button { id: wrapToggle; text: "Unwrap" }
					TextWidget { text: "Append:" }
					CheckBox { id: checkBoxAppend; }
				}
				HorizontalLayout {
					TextWidget {
						text: "Extract (from right to left) with title:"
					}
					EditLine {
						id: editLineTitle
						minWidth: 990
					}
					Button {
						id: buttonActivateExtractTitle
						text: "Extract Title"
					} 
				}
				HorizontalLayout {
					TextWidget {
						text: "Extract (from right to left) with title and sub title:"
					}
					EditLine {
						id: editLineTitleAndSubTitle
						minWidth: 690
					}
					Button {
						id: buttonActivateExtractTitleAndSubTitle
						text: "Extract Title and Sub Title"
					} 
				}
			}
		});

		_editBoxMain = _window.mainWidget.childById!EditBox("editBoxMain");
		_editBoxRight = _window.mainWidget.childById!EditBox("editBoxRight");
		_editBoxHistory = _window.mainWidget.childById!EditBox("editBoxHistory");
		_editLineInWindowSpot = _window.mainWidget.childById!EditLine("editLineInWindowSpot");
		_checkBoxSearchCaseSensitive = _window.mainWidget.childById!CheckBox("checkBoxSearchCaseSensitive");
		_editLineSearch = _window.mainWidget.childById!EditLine("editLineSearch");
		_checkBoxPartWordSearch = _window.mainWidget.childById!CheckBox("checkBoxPartWordSearch");
		_checkBoxWordSearch = _window.mainWidget.childById!CheckBox("checkBoxWordSearch");
		_checkBoxPhraseSearch = _window.mainWidget.childById!CheckBox("checkBoxPhraseSearch");
		_wrapToggle = _window.mainWidget.childById!Button("wrapToggle");
		_checkBoxAppend = _window.mainWidget.childById!CheckBox("checkBoxAppend");
		_editLineTitle = _window.mainWidget.childById!EditLine("editLineTitle");
		_editLineTitleAndSubTitle = _window.mainWidget.childById!EditLine("editLineTitleAndSubTitle");

		_checkBoxPartWordSearch.checked = false;
		_checkBoxWordSearch.checked = true;
		_checkBoxPhraseSearch.checked = false;
		_checkBoxSearchCaseSensitive.checked = false;
		_checkBoxAppend.checked = true;

		resetVerseTags;

		void doAppendQ() {
			if (_checkBoxAppend.checked == false) {
				_editBoxMain.text = "";
				resetVerseTags;
			}
		}

		_window.mainWidget.childById!Button("buttonActivateExtractTitleAndSubTitle").click = delegate(Widget w) {
			doAppendQ;
			processTask("extractSubNotes "d ~ _editLineTitleAndSubTitle.text);

			return true;
		};

		_window.mainWidget.childById!Button("buttonActivateExtractTitle").click = delegate(Widget w) {
			doAppendQ;
			processTask("extractNotes "d ~ _editLineTitle.text);

			return true;
		};

		//#buggy?
		_editBoxMain.wordWrap = true;
		_editBoxRight.wordWrap = true;
		_editBoxHistory.wordWrap = true;

		_window.mainWidget.childById!Button("wrapToggle").click = delegate(Widget w) {
			immutable wboxes = "(text boxes: main box, right box, history box)";
			if (true == _editBoxMain.wordWrap) {
				_editBoxMain.wordWrap = false;
				_editBoxRight.wordWrap = false;
				_editBoxHistory.wordWrap = false;
				_wrapToggle.text = "Wrap"d;
				addToHistory("Unwrapped text ", wboxes);
			} else {
				_editBoxMain.wordWrap = true;
				_editBoxRight.wordWrap = true;
				_editBoxHistory.wordWrap = true;
				_wrapToggle.text = "Unwrap"d;
				addToHistory("Wrapped text ", wboxes);
			}
			return true;
		};

		_window.mainWidget.childById!Button("buttonActivateSearch").click = delegate(Widget w) {
			doAppendQ;
			auto caseSensitive = _checkBoxSearchCaseSensitive.checked ? "%caseSensitive "d : ""d;
			if (_checkBoxPhraseSearch.checked)
				processTask("ps "d ~ caseSensitive ~ _editLineSearch.text);
			if (_checkBoxPartWordSearch.checked)
				processTask("pws "d ~ caseSensitive ~ _editLineSearch.text);
			if (_checkBoxWordSearch.checked)
				processTask("ws "d ~ caseSensitive ~ _editLineSearch.text);
			
			return true;
		};

		_window.mainWidget.childById!Button("buttonClearLeft").click = delegate(Widget w) {
			_editBoxMain.text = "";
			resetVerseTags;
			addToHistory("Cleared main text box. Reset tags (eg. for search within last search).");
			
			return true;
		};

		_window.mainWidget.childById!Button("buttonWrap").click = delegate(Widget w) {
			import std.string: split, wrap;

			dstring s;
			foreach(line; _editBoxMain.text.split("\n"))
				s ~= wrap(line, g_editBoxsWrapWidth, null, null, 4);
			_editBoxMain.text = s;

			addToHistory("Main text wrap by inserting new line characters.");

			return true;
		};

		_window.mainWidget.childById!Button("buttonExpVers").click = delegate(Widget w) {
			doAppendQ;
			processTask("expVers");

			return true;
		};

		_window.mainWidget.childById!Button("buttonActivate").click = delegate(Widget w) {
			doAppendQ;
			processTask(_editLineInWindowSpot.text);

			return true;
		};

		_editBoxMain.text = "At the 'Enter command'\n" ~
			"box type in 'h'\n" ~
			"and hit Activate\n";

		addToHistory("Welcome to Jyble");

		_window.show();

		return 0;
	}

	auto processTask(T)(in T oinput) {
		string output;

		import std.stdio;
		import std.conv;

		auto input = oinput.to!string;

		_doVerse = true;
		if (input.length) {
			immutable base = input.split[0];
			immutable args = input.split[1 .. $];

			_doVerse = false;
			switch(base) {
				default: _doVerse = true; break;
				case "q", "quit", "exit":
					output = "Hold down [Command] and tap [Q] to quit";
					addToHistory("Show quit instructions");
				break;
				case "marker":
					int len = 10;
					enum error = "Invalid input";

					if (args.length == 0)
						output = error;
					else
						try { len = args[0].to!int; } catch(Exception e) { output = error; }
					foreach(l; 1 .. len + 1) {
						auto line = "#".replicate(l) ~ "\n";
						l == 0 ? output = line : (output ~= line);
					}
					addToHistory("Show marker");
				break;
				case "h", "help":
					output = _helpTxt;
					addToHistory("Display help");
				break;
				case "extractNotes":
					if (args.length == 0) {
						output = "Notes Extraction:\n" ~ getNotesSortDaysToText(_editBoxRight.text.to!string);
						addToHistory("Notes Extraction, with no arguments");
					} else {
						immutable title = args.join(" ");
						output = "Notes Extraction:\n" ~ getNotesSortFromTitle(title, _editBoxRight.text.to!string);
						addToHistory("Notes Extraction: " ~ title);
					}
				break;
				// extractSubNotes Bible \/ Snare1.pdf \/b
				case "extractSubNotes":
					immutable title = args.join(" ")[0 .. args.join(" ").indexOf(` \/`) + 3];
					immutable subTitle = args.join(" ")[title.length + 1 .. $];

					output = "Sub notes Extraction:\n" ~ getNotesSortFromTitleAndSubTitle(title, subTitle,
						_editBoxRight.text.to!string);
					addToHistory("Sub notes Extraction: " ~ title ~ " " ~ subTitle);
				break;
				case "bible":
					import std.algorithm: any;
					import std.string: toLower, toUpper;

					auto biblesList = "esv kjv";
					auto bibleVersion = args[0].toLower;
					if (args.length == 1 && any!(a => a == bibleVersion)(biblesList.split)) {
						loadBible(bibleVersion);
						output = text(bibleVersion, " Bible version loaded..");
						addToHistory("Set Bible version to: ", bibleVersion.toUpper);
					} else {
						output = args[0] ~ " - Invalid input, use one of these: " ~ biblesList;
						addToHistory("Invalid Bible version: ", bibleVersion);
					}
				break;
				case "i", "info":
					output = g_info.toString;
					addToHistory("Show info");
				break;
				case "expVers":
					if (args.length) {
						if (args[0].exists) {
							auto fileName = "exp_" ~ args[0];
							
							output = g_bible.expVers(args[0], fileName) ~ "\n";
							output ~= "Out put file " ~ fileName;
							addToHistory("expVers file name: ", args[0]);
						} else {
							output = args[0] ~ " - filename does not exist in folder!";
						}
					} else {
						if (_editBoxRight.text != ""d) {
							output = g_bible.expVers("dummy1", "dummy2", _editBoxRight.text.to!string);
							addToHistory("expVers from the main right");
						} else {
							output = "Empty right box!";
							addToHistory("Empty right box!");
						}
					}
				break;
				//#upto with history
				case "everyBook": // `everyBook 1 1` eg. Gen 1 1 .., Exo 1 1 ..
					auto args2 = args.dup;
					try {
						int chp = 1, ver = 1;
						foreach(n; 1 .. 66 + 1) {
							string result;
							
							//#I don't see "n" doing any thing?!
							//if wild card, use counter
							if (args[0] == "n")
								args2[0] = chp.to!string;

							if (args[1] == "n")
								args2[1] = ver.to!string;

							result = n.to!string ~ " " ~ args2.join(" ");
							auto output2 = g_bible.argReference(g_bible.argReferenceToArgs(result));
							if (output2 != "")
								output ~= output2;

							chp += 1;
							ver += 1;
						}
						addToHistory("Every book: ", args2.join(":"));
					}
					catch(Exception e) {
						output = "Could not be done!";
						addToHistory("Every book: could not be done!");
					}
				break;
				case "everyChp": // Joh n 1 (John 1 1 (verse), John 2 1 (verse) etc)
						try {
							if (args.length > 2) {
								foreach(n; 1 .. g_bible.getBook(g_bible.bookNumberFromTitle(args[0])).m_chapters.length + 1) {
									string result;

									result = text(args[0], ' ', n.to!string, ' ', args[2 .. $].join(" "));
									output ~= g_bible.argReference(g_bible.argReferenceToArgs(result));
								}
							}
							addToHistory("EveryChp: ", args.join(" "));
						}
						catch(Exception e) {
							output = "Could not be done!";
							addToHistory("EveryChp: ", output);
						}
				break;
				case "books":
					foreach(bn; iota(1, 23, 1)) {
						string bookName(in int start) {
							return g_bible.getBook(start + bn).m_bookTitle ~ "\t";
						}

						string[] bookNames;
						bookNames ~= bookName(00);
						bookNames ~= bookName(22);
						bookNames ~= bookName(44);

						// eg. 1 ---- Genesis
						string numLineNBookName(int start, in string bookName) {
							import std.array : replicate;

							return (start + bn).to!string ~
								(start + bn < 10 ? " -" : " ") ~ "-".replicate(17 - bookName.length) ~ " " ~ bookName;
						}

						output ~= format("%20s%20s%20s\n",
							numLineNBookName(0, bookNames[0]),
							numLineNBookName(22, bookNames[1]),
							numLineNBookName(44, bookNames[2]));
					}
					addToHistory("List books");
				break;
				case "wrap":
					if (args.length == 0) {
						g_wrap = (g_wrap ? false : true);
						output = "Text wrap is " ~ (g_wrap ? "on" : "off");
						addToHistory("Wrap: ", output);
					} else {
						if (args.length == 1) {
							g_wrap = true;
							try {
								g_wrapWidth = args[0].to!int;
								output = "Wrap width set";
								addToHistory(output);
							} catch(Exception e) {
								g_wrap = false;
								output = "Error, text wrap has defaulted to off.";
								addToHistory(output);
							}
						}
					}
				break;
				case "btn":
					if (args.length == 1) {
						try {
							output = text("Book: ", args[0], " number: ", g_bible.bookNumberFromTitle(args[0]).to!string);
							addToHistory("Book number: ", args[0]);
						} catch(Exception e) {
							output = "Invalid book name";
							addToHistory("Book number: ", output);
						}
					} else {
						output = "You missed the name of the book!";
						addToHistory("Book number: ", output);	
					}
				break;
				/+
				case "els":
					size_t bookNumber, startNumber = 1;
					if (args.length == 3) {
						string s = args[2];
						try {
							startNumber = s.parse!size_t;
						} catch(Exception e) {
							output = text(s, " - invalid start number.");
							break;
						}
					}
					if (startNumber <= 0) {
						output = "Too lower start number.";
						break;
					}
					if (args.length >= 2) {
						if (args[0].length == 1) {
							output = "You need more than one character!";
							break;
						}
						try { //20 + 32 + 21 = 73
							output = equalDistanceLetterSequence(
								args[0],
								g_bible.bookNumberFromTitle(args[1]) - 1, startNumber);
						} catch(Exception e) {
							output = "Input error..";
						}
					}
				break;
				+/
				case "ps":
					output = args.join(" ").phraseSearch;
					addToHistory("Phrase search: '", args.join(" "), "'");
				break;
				case "ws":
					auto argsa = cast(string[])args;
					output = argsa.wordSearch(WordSearchType.wholeWords);
					addToHistory("Whole Word search: ", args.join(" "));
				break;
				case "pws":
					// can have word parts (house - can find houses, notice the s)
					auto argsa = cast(string[])args;
					output = argsa.wordSearch(WordSearchType.wordParts);
					addToHistory("Part Word search: ", args.join(" "));
				break;
				case "chp":
					if (args.length == 1) {
						int index;
						auto argsa = cast(string)args[0];
						try {
							index = argsa.parse!int - 1;
						} catch(Exception e) {
							output = "Invalid number for chapter!";
							addToHistory(output);
							break;
						}
						if (index >= 0 && index < g_forChapter.length) {
							output = g_bible.argReference(g_bible.argReferenceToArgs(g_forChapter[index]));
							addToHistory("Chapter from index number: ", index);
						} else {
							output = "Out of range";
							addToHistory("Chapter from index: ", output);
						}
					} else {
						if (args.length == 0) {
							output = "Start again, but enter missing chapter number!";
							addToHistory("Chapter from index: ", output);
						} else {
							output = "Wrong number of operants!";
							addToHistory("Chapter from index: ", output);
						}
					}
				break;
			} // switch
		}
		if (_doVerse) {
			auto history = input;
			if (input.length > 2) {
				size_t end = input.indexOf("->");
				if (end == -1)
					end = input.length;
				input = input[0 .. end].strip;
			}
			output = g_bible.argReference(g_bible.argReferenceToArgs(input));
			addToHistory(history);
		}

		if (output != "") {
			_editBoxMain.text = _editBoxMain.text ~ text(_editBoxMain.text != "" ? "\n" : "",
				output).to!dstring;
		}
	}

	void addToHistory(T...)(in T args) {
		immutable status = upDateStatus(args).to!dstring;
		_editBoxHistory.text = _editBoxHistory.text ~ status;
		//_textWidgetStatus.text = status;
	}

} // main

/// entry point for dlangui based application
extern (C) int UIAppMain(string[] args) {
	scope(exit) {
		import std.stdio : writeln;

		writeln;
		writeln("## ");
		writeln("# #");
		writeln("## ");
		writeln("# #");
		writeln("## ");
		writeln;
	}

        // just in case, but dlangui package seems to import pretty much everything
        import dlangui.core.types;

        // pretty much self explanatory, where 96 DPI is "normal" 100% zoom
        // alternatively you can set it to your screen real DPI or PPI or whatever it is called now
        // however for 4k with 144 DPI IIRC I set it to 1.25 scale because 1.5 was too big and/or didn't match WPF/native elements
	version(retinaDisplay)
		overrideScreenDPI = cast(int)(96f * SCALE_FACTOR);

	MainWindow mainWindow;
	mainWindow.setup;

    // run message loop
    return Platform.instance.enterMessageLoop();
}
