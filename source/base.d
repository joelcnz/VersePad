module base;

public {
	import std.conv;
	import std.datetime.stopwatch;
	import std.range;
	import std.stdio;
	import std.string;

    import arsdlib = arsd.dom;
}

public import jecsdl, bible, jmisc;

immutable newline = "\n"; /// new line character
enum YES = true; /// yes or true
enum NO = false; /// no or false

arsdlib.Document g_document; /// dom document, or so
LetterManager g_letterBase; /// main text
string g_fileName; /// text file name

/// status add
void updateFileNLetterBase(T...)(T args) {
	g_letterBase.addTextln(args);
	upDateStatus(args);
}

StopWatch g_sw; /// Stop watch

shared static this() {
	g_sw.start;
}
