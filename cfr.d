module cfr;

import std.stdio : writeln;
import std.process : wait, spawnProcess;
import std.string : join;

void main() {
    immutable commands = [["clear"],
        ["dub", "build"],
        ["./verpad", "Testing"]];
    foreach(i, command; commands) {
        writeln("D> ", command.join(" "));
        wait(spawnProcess(command));
        if (i == 0)
            writeln("D> ", command.join(" "), " (screen cleared)");
    }
}
