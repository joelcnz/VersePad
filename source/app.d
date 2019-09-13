module app;

//#Bible

import base;

enum programName = "Verse Pad"; /// Program name
enum projects = "Projects"; /// List of projects

/**
	The Main
 */
int main(string[] args) {
	scope(exit) {
		writeln;
		writeln("#  #");
		writeln("## #");
		writeln("####");
		writeln("# ##");
		writeln("#  #");
		writeln;
	}

	version(OSX) {
		writeln("This is a Mac version of " ~ programName);
	}
	version(Windows) {
		writeln("This is a Windows version of " ~ programName);
	}
	version(linux) {
		writeln("This is a Linux version of " ~ programName);
	}

    //writeln("Ovr a million: ", addCommas(1_234_567));

    immutable retVal = setupAndStuff(args);
	if (retVal != 0) {
        if (retVal == -10)
            writeln("You must pass a name (eg. './verpad Joel')");
        else
            writeln("Error in setupAndStuff!");
	}

	return 0;
}

/// Set up stuff
auto setupAndStuff(in string[] args) {
    string userName;
    if (args.length > 1) {
        import std.string: join;

        userName = args[1 .. $].join(" ");
    } else {
        return -10;
    }
	immutable WELCOME = "Welcome, " ~ userName ~ ", to " ~ programName;
	g_window = new RenderWindow(VideoMode(1920, 1080),
						WELCOME);
    g_checkPoints = true;
    if (int retVal = jec.setup != 0) {
        import std.stdio: writefln;

        writefln("File: %s, Error function: %s, Line: %s, Return value: %s",
            __FILE__, __FUNCTION__, __LINE__, retVal);
        return -2;
    }

    immutable g_fontSize = 40;
    g_font = new Font;
    g_font.loadFromFile("DejaVuSans.ttf");
    if (! g_font) {
        import std.stdio: writeln;
        writeln("Font not load");
        return -3;
    }

    //immutable size = 100, lower = 40;
    immutable size = g_fontSize, lower = g_fontSize / 2;
    jx = new InputJex(/* position */ Vector2f(0, g_window.getSize.y - size - lower),
                    /* font size */ size,
                    /* header */ "Word: ",
                    /* Type (oneLine, or history) */ InputType.history);
    jx.setColour(Color(255, 200, 0));
    jx.addToHistory(""d);
    jx.edge = false;

	//#Bible
	immutable BIBLE_VER = "esv"; // "jkv";
	loadBible(BIBLE_VER);

    g_mode = Mode.edit;
    g_terminal = true;

    jx.showHistory = false;

    g_window.setFramerateLimit(60);

	g_letterBase = new LetterManager("lemblue.png", 8, 17,
        Square(0,0, g_window.getSize.x, g_window.getSize.y));
    assert(g_letterBase, "Error loading bmp");

    updateFileNLetterBase(WELCOME, newline);
    g_letterBase.setLockAll(true);

    string[] files;

    doProjects(files, /* show */ false);
    run(files);

	return 0;
}

/// Run program
void run(string[] files) {
    import std.file : readText;
    import std.path : buildPath;
    //import std.string : ;

    auto helpText = readText("_notes.txt");
    with(g_letterBase)
        setTextType(TextType.line);
    scope(exit)
        g_window.close();
    string userInput;
    bool enterPressed = false; //#enter pressed
    int prefix;
    prefix = g_letterBase.count();
    auto firstRun = true;
    auto done = NO;
    while(! done) {
        if (! g_window.isOpen())
            done = YES;

        Event event;

        while(g_window.pollEvent(event)) {
            if(event.type == event.EventType.Closed) {
                done = YES;
            }
        }

        version(OSX)
            if ((Keyboard.isKeyPressed(Keyboard.Key.LSystem) ||
                Keyboard.isKeyPressed(Keyboard.Key.RSystem)) &&
                Keyboard.isKeyPressed(Keyboard.Key.Q))
                done = YES;
        //#windows version needed for short cut to quit

        // print for prompt, text depending on whether the section has any verses or not
        /+
        if (enterPressed || firstRun) {
            firstRun = false;
            enterPressed = false;
            //if (! done)
            //    updateFileNLetterBase("Enter verse reference:");
            g_letterBase.setLockAll(true);
            prefix = g_letterBase.count();
        }
        +/
        // exit program if set to exit else get user input
        if (done == NO) {
            import std.string : toLower;
            g_window.clear;
            
            g_letterBase.draw();

            with( g_letterBase ) {
                doInput(/* ref: */ enterPressed);
                update(); //#not much
            }

            g_window.display;
            
            if (enterPressed) {
                //g_letterBase.addText("\n");
                /+  
                size_t len = g_letterBase.getText.length;
                if (prefix < 0 || prefix >= len) {
                    "whoops..".gh;
                } else { +/
                    userInput = g_letterBase.getText[prefix .. $].stripRight;
                    upDateStatus(userInput);
                //}
                
                //auto txt = g_letterBase.getText;
                //userInput = txt[txt.lastIndexOf("\n") + 1 .. $];
            }
        }
        if (userInput.length > 0) {
            import std.string: toLower;

            // If command not used, the user input is treated as thing typed from memory
            // Switch on command
            const args = userInput.split[1 .. $];
            switch (userInput.split[0].toLower) {
                // Display help
                case "help":
                    updateFileNLetterBase(helpText);
                break;
                case "projects":
                    doProjects(files);
                break;
                case "load":
                    if (args.length != 1) {
                        updateFileNLetterBase("Wrong amount of parameters!");
                        break;
                    }
                    try {
                        import std.conv : to;

                        const index = args[0].to!int;
                        if (index >= 0 && index < files.length)
                            g_fileName = files[index];
                        else
                            throw new Exception("Index out of bounds");
                    } catch(Exception e) {
                        updateFileNLetterBase("Input error!");
                        break;
                    }
                    loadProject(g_fileName);
                    updateFileNLetterBase(g_fileName, " - project loaded..");
                break;
				case "save":
                    if (args.length == 0) {
                        updateFileNLetterBase("File name missing!");
                        break;
                    }
					int index;
					try {
                        import std.conv : to;
                        index = args[0].to!int;
						if (index >= 0 && index < files.length)
							g_fileName = files[index];
					} catch(Exception e) {
						import std : join;
						g_fileName = args.join(" ") ~ ".txt";
					}
					import std.stdio : File, write;
					import std : buildPath;
                    File(buildPath(projects,g_fileName), "w").write(g_letterBase.getText);
                    updateFileNLetterBase(g_fileName, " - project saved..");
				break;
                case "cls", "clear":
                    clearScreen;
                    updateFileNLetterBase("Screen cleared..");
                break;
                // quit program
                case "exit", "quit", "command+q", ":q":
                    done = true;
                break;
                default:
					assert(g_bible, "Bible unallocated!");
					import std : indexOf, strip;
					size_t end = userInput.indexOf("->");
					if (end == -1)
						end = userInput.length;
					auto refe = userInput[0 .. end].strip;
					updateFileNLetterBase(g_bible.argReference(g_bible.argReferenceToArgs(refe)).stripRight);
                break;
            }
        }
        if (enterPressed) {
            enterPressed = false;
            userInput.length = 0;
            g_letterBase.setLockAll(true);
            prefix = g_letterBase.count();
        }
    }
}

/// clear the screen
void clearScreen() {
    g_letterBase.setText("");
}

/// Collect project files
void doProjects(ref string[] files, in bool show = true) {
    import std.file: dirEntries, SpanMode;
    import std.path: buildPath, dirSeparator, stripExtension;
    import std.range: enumerate;
    import std.string: split;

    if (show)
        updateFileNLetterBase("File list:");
    files.length = 0;
    foreach(i, string name; dirEntries(buildPath(projects), "*.{txt}", SpanMode.shallow).enumerate) {
        import std.conv: to;

        //name = name.split(dirSeparator)[1];
        if (show)
            updateFileNLetterBase(i, " - ", name.stripExtension);
        files ~= name;
    }
}

/// Load project
void loadProject(in string fileName) {
    import std : readText, exists;
 
	auto filen = fileName;
	if (filen.exists) {
		g_fileName = fileName;
	    g_letterBase.setText(readText(filen));
	} else
		g_letterBase.addText(filen," - not found");
}
