-- JXA `move` fails with "Can't convert types" on Things lists; AppleScript works. Args come via argv, never interpolated.
on run argv
	tell application "Things3" to move (to do id (item 1 of argv)) to list (item 2 of argv)
end run
