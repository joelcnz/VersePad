module scraps.scraps;

    if (args.length == 2) {
        import std.file : readText;
        import std.path : buildPath, setExtension;
        //import std.string : ;

        auto text = readText(args[1]);
        with(g_letterBase)
            setTextType(TextType.line),
            setText(text);
        scope(exit)
            g_window.close();
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

            g_window.clear;

            g_letterBase.draw();

            with( g_letterBase ) {
                update(); //#not much
            }

            g_window.display;
        }
    }
