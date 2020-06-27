//#need more work (DRY problem)
//#line ?!
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

    //writeln("Over a million: ", addCommas(1_234_567));

    string userName;
    if (args.length > 1) {
        import std.string: join;

        userName = args[1 .. $].join(" ");
    } else {
        writeln("Identify your self, next time - ok");
        return -10;
    }
	immutable WELCOME = "Welcome, " ~ userName ~ ", to " ~ programName;

    //SCREEN_WIDTH = 2560; SCREEN_HEIGHT = 1600;
    //SCREEN_WIDTH = 1920; SCREEN_HEIGHT = 1080;
    SCREEN_WIDTH = 1280; SCREEN_HEIGHT = 800;
    if (setup(WELCOME,
        SCREEN_WIDTH, SCREEN_HEIGHT,
        SDL_WINDOW_SHOWN
        //SDL_WINDOW_OPENGL
        //SDL_WINDOW_FULLSCREEN_DESKTOP
        //SDL_WINDOW_FULLSCREEN
        ) != 0) {
        writeln("Init failed");
        return 1;
    }

	const ifontSize = 12;
	jx = new InputJex(Point(0, SCREEN_HEIGHT - ifontSize - ifontSize / 4), ifontSize, "H for help>",
		InputType.history);
	g_terminal = false;
    jx.setColour(SDL_Color(255, 200, 0, 255));
    jx.addToHistory(""d);
    jx.edge = false;

	//#Bible
    import std.path : buildPath;
	immutable BIBLE_VER = "asv"; //""kjv";
	loadBible(BIBLE_VER, buildPath("..", "BibleLib", "Versions"));

    //g_mode = Mode.edit;
    g_terminal = true;

    jx.showHistory = false;

//    g_window.setFramerateLimit(60);

	g_letterBase = new LetterManager(["lemblue.png", "lemgreen32.bmp"], 8, 17,
        SDL_Rect(0,0, SCREEN_WIDTH, SCREEN_HEIGHT));
        //SDL_Rect(100,50, 10 * 8,240));
    //assert(g_letterBase, "Error loading bmps");

    updateFileNLetterBase(WELCOME, newline);
    g_letterBase.setLockAll(true);

    string[] files;

    doProjects(files, /* show */ false);
    run(files);

	return 0;
}

/// Run program
void run(string[] files) {
    scope(exit)
        SDL_DestroyRenderer(gRenderer),
        SDL_Quit();

    import std.file : readText;
    import std.path : buildPath;
    //import std.string : ;

    auto helpText = readText("_notes.txt");
    with(g_letterBase)
        setTextType(TextType.block); //#line ?!
    scope(exit)
       close();
    string userInput;
    bool enterPressed = false; //#enter pressed
    int prefix;
    prefix = g_letterBase.count();
    auto firstRun = true;
    auto done = NO;
	
	SDL_Event event;
    g_letterBase.currentGfxIndex(0);
    while(! done) {
        SDL_PumpEvents();

		SDL_PollEvent(&event);
		if(event.type == SDL_QUIT) // not work?!
			done = YES;

        if (g_keys[SDL_SCANCODE_LGUI].keyPressed ||
            g_keys[SDL_SCANCODE_RGUI].keyPressed) {
            if (g_keys[SDL_SCANCODE_1].keyInput) {
                g_letterBase.currentGfxIndex(1);
            }
            if (g_keys[SDL_SCANCODE_2].keyInput) {
                g_letterBase.currentGfxIndex(0);
            }
        }

        //#windows version needed for short cut to quit

        // print for prompt, text depending on whether the section has any verses or not
        if (enterPressed || firstRun) {
            firstRun = false;
            if (firstRun)
                enterPressed = false;
            if (! done)
                updateFileNLetterBase("Enter verse reference:");
            //g_letterBase.currentGfxIndex(0);
            g_letterBase.setLockAll(true);
            prefix = g_letterBase.count();
            //g_letterBase.currentGfxIndex(1);
        }

        // exit program if set to exit else get user input
        if (done == NO) {
            SDL_SetRenderDrawColor(gRenderer, 0x00, 0x00, 0x00, 0xFF);
            SDL_RenderClear(gRenderer);
            
            g_letterBase.draw();

            g_letterBase.doInput(/* ref: */ enterPressed);
            g_letterBase.update(); //#not much
            
            SDL_RenderPresent(gRenderer);

            if (enterPressed) {
                //g_letterBase.addText("\n");
                /+  
                size_t len = g_letterBase.getText.length;
                if (prefix < 0 || prefix >= len) {
                    "whoops..".gh;
                } else { +/
                if (g_letterBase.getText.length > 0) {
                    userInput = g_letterBase.getText[g_letterBase.getText.stripRight.lastIndexOf('\n') + 1 .. $].stripRight;

                    upDateStatus(userInput);
                } else {
                    //text("Error with prefix: ", prefix, ", getText: ", g_letterBase.getText.length).gh;
                }
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
            string fileNameTmp;
            if (args.length) {
                try {
                    import std.conv : to;

                    const index = args[0].to!int;
                    if (index >= 0 && index < files.length)
                        fileNameTmp = files[index];
                } catch(Exception e) {
                    import std.file : exists;
                    import std.path : buildPath;
                    if (args[0] ~ ".txt".exists)
                        fileNameTmp = args[0] ~ ".txt";
                    else
                        fileNameTmp = buildPath("Projects", args[0] ~ ".txt");
                }
            }
            switch (userInput.split[0].toLower) {
                // Display help
                case "help":
                    updateFileNLetterBase(helpText);
                break;
                case "edit":
                    import std.process : wait, spawnProcess;
                    import std.file : exists;
                    if (g_fileName.exists)
                        wait(spawnProcess(["open", g_fileName]));
                    else
                        updateFileNLetterBase("Select a project.");
                break;
                case "projects":
                    doProjects(files);
                break;
                case "load":
                    if (args.length != 1) {
                        updateFileNLetterBase("Wrong amount of parameters!");
                        break;
                    }
                    g_fileName = fileNameTmp;
                    loadProject(g_fileName);
                    updateFileNLetterBase(g_fileName, " - project loaded..");
                break;
                //#need more work (DRY problem)
				case "save":
                    //if (args.length == 0) {
                    //    updateFileNLetterBase("File name/index number missing!");
                    //    break;
                    //}
                    import std.file : exists;
                    if (args.length == 0 && g_fileName.exists) {
                        updateFileNLetterBase("Under construction..");
                        /+
                        import std.stdio : File, write;
                        File(g_fileName, "w").write(g_letterBase.getText);
                        updateFileNLetterBase(g_fileName, " - project saved..");
                        +/
                        break;
                    }
					int index;
					try {
                        import std.conv : to;
                        index = args[0].to!int;
						if (index >= 0 && index < files.length) {
							g_fileName = files[index];
                        }
					} catch(Exception e) {
						import std : join;
						g_fileName = args.join(" ") ~ ".txt";
					}
					import std.stdio : File, write;
                    File(g_fileName, "w").write(g_letterBase.getText);
                    updateFileNLetterBase(g_fileName, " - project saved..");
				break;
                case "delete":
                    if (args.length != 1) {
                        updateFileNLetterBase("Wrong amount of parameters!");
                        break;
                    }
                    deleteProject(g_fileName);
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
                    if (userInput.length) {
                        assert(g_bible, "Bible unallocated!");
                        import std : indexOf, strip;
                        size_t end = userInput.indexOf("->");
                        if (end == -1)
                            end = userInput.length;
                        auto refe = userInput[0 .. end].strip;
                        auto bible = g_bible.argReference(g_bible.argReferenceToArgs(refe)).stripRight;
                        if (bible.length > 2)
                            updateFileNLetterBase(bible);
                    }
                break;
            }
        } // if (userInput.length > 0) {
        if (enterPressed) {
            enterPressed = false;
            userInput.length = 0;
            g_letterBase.setLockAll(true);
            prefix = g_letterBase.count();
        }
        SDL_Delay(2);
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
        import std.conv : to;

        if (show)
            updateFileNLetterBase(i, " - ", name[name.indexOf(dirSeparator) + 1 .. $].stripExtension);
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
		g_letterBase.addText(" ", filen, " - not found");
}

void deleteProject(in string fileName) {
    import std : remove, exists;
 
	auto filen = fileName;
	if (filen.exists) {
		g_fileName = "";
	    remove(filen);
        g_letterBase.addText(filen, " - deleted");
	} else
		g_letterBase.addText(filen, " - not found");
}