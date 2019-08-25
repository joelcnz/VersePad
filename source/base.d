module base;

public {
    /+
	import std.conv;
	import std.datetime.stopwatch;
	import std.range;
	import std.stdio;
	import std.string;
+/
    import std;

    import arsdlib = arsd.dom;
}

public import jec, bible.bible, bible.book, bible.chapter, bible.verse, bible.misc;

immutable newline = "\n";
enum YES = true, NO = false;

arsdlib.Document g_document;
Bible g_bible;
LetterManager g_letterBase;
Info g_info;

struct Info {
	string bibleVersion,
		   book;
	int chapter,
		verse,
		verseCount,
		chapterCount;
	
	string toString() const {
		import std.conv: text;

		if (book == "")
			return text("Bible: ", bibleVersion);
		return text("Bible: ", bibleVersion, "\n",
					"Book: ", book, "\n",
					"Chapter: ", chapter, "\n",
					"Verse: ", verse, "\n",
					"Total chapter verses: ", verseCount, "\n",
					"Total chapters: ", chapterCount, "\n",
					'-'.repeat(3));
	}
}

void updateFileNLetterBase(T...)(T args) {
	g_letterBase.addTextln(args);
	upDateStatus(args);
}

StopWatch g_sw;

static this() {
	g_sw.start;
}

void loadBible(in string ver) {
	switch(ver) {
		default: writeln(ver, " Invalid input"); break;
		case "esv":
			g_info.bibleVersion = "English Standard Version";
			writeln(g_info.bibleVersion);
			loadXMLFile();
			parseXMLDocument();
		break;
		case "kjv":
			import bible.kjv;
		
			g_info.bibleVersion = "King James Version";
			writeln(g_info.bibleVersion);
			auto kjv = new jkBible(readText("kjvtext.txt"));
			kjv.convertToJyble();
		break;
	}
}

void loadXMLFile() {
	writeln( "Loading xml file.." );
    g_document = new arsdlib.Document(readText("esv.xml"));
}

void parseXMLDocument() {
	writeln( "Processing xml loaded document file.." );

    // the document is now the bible
    g_bible = new Bible;

    auto books = g_document.getElementsByTagName("b");
    foreach(i, book; books) {
       //auto nameOfBook = book.n; // "Genesis" for example. All xml attributes are available this same way

		//book.n = book.n.replace(" ", ""); //#makes SongOfSolomon
		alias b = book;
		debug(5) writeln([b.attrs.n]);
		if (b.attrs.n[1] == ' ')
			b.attrs.n = b.attrs.n[0] ~ b.attrs.n[2 .. $];
		g_bible.m_books ~= new Book(b.attrs.n);

       auto chapters = book.getElementsByTagName("c");
       foreach(chapter; chapters) {
            auto verses = chapter.getElementsByTagName("v");
            
         	g_bible.m_books[$ - 1].m_chapters ~= new Chapter( chapter.attrs.n );

            foreach(verse; verses) {
                 auto v = verse.innerText;

				g_bible.m_books[$ - 1].m_chapters[$ - 1].m_verses ~= new Verse( verse.attrs.n );
				g_bible.m_books[$ - 1].m_chapters[$ - 1].m_verses[$ - 1].verse = v;
//                 // let's write out a passage
                //writeln(g_bible.m_books[$ - 1].m_bookTitle, " ", chapter.n, ":", verse.n, " ", v); // prints "Genesis 1:1 In the beginning, God created [...]
            }
       }
    }
    
}
