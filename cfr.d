module cfr;

import std.process;
void main() {
    wait(spawnProcess(["clear"]));
    wait(spawnProcess(["dub", "build"]));
    wait(spawnProcess(["./verpad", "Testing"]));
}