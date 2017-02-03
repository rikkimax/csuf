/**
 * Implements a simple reader for Command Sequence Unoriginal Format
 * 
 * Authors:
 *    Richard Andrew Cattermole
 * 
 * License:
 *              Copyright Richard Andrew Cattermole 2004 - 2006.
 *     Distributed under the Boost Software License, Version 1.0.
 *        (See accompanying file LICENSE_1_0.txt or copy at
 *              http://www.boost.org/LICENSE_1_0.txt)
 */
module csuf.reader;
import std.traits : isSomeString;

///
struct CommandSequenceReader(String) if (isSomeString!String) {
	private {
		String[] allArgsCommands, allArgsInformation, allArgsInformationCommands;
		Item!String[] allCommands, allInformation, allInformationCommands;
	}
	
	///
	Entry!String[] entries;
	
	///
	this(String sourceText, String resetCommand = "new") {
		import std.algorithm : sum, map, count, splitter;
		import std.string : lineSplitter, strip;
		
		auto countCommands = sourceText
			.lineSplitter
				.map!strip
				.map!(line => (line.length > 0 && line[0] == '.' && ((line.length > 1 && line[1] != '.') || line.length == 1)) ? 1 : 0)
				.sum;
		auto countInformationCommands = sourceText
			.lineSplitter
				.map!strip
				.map!(line => (line.length > 1 && line[0] == '.' && line[1] == '.') ? 1 : 0)
				.sum;
		auto countInformation = sourceText
			.lineSplitter
				.map!strip
				.map!(line => (line.length > 0) ? 1 : 0)
				.sum - countCommands;
		
		auto countEntries = sourceText
			.lineSplitter
				.map!strip
				.map!(line => (line.length > resetCommand.length && line[0] == '.' && line[1 .. resetCommand.length+1] == resetCommand) ? 1 : 0)
				.sum;
		auto countArgsCommand = sourceText
			.lineSplitter
				.map!strip
				.map!(line => (line.length > 0 && line[0] == '.' && ((line.length > 1 && line[1] != '.') || line.length == 1)) ? line.count(' ') : 0)
				.sum;
		auto countArgsInformation = sourceText
			.lineSplitter
				.map!strip
				.map!(line => (line.length > 0 && line[0] != '.') ? line.count(' ') : 0)
				.sum;
		auto countArgsInformationCommand = sourceText
			.lineSplitter
				.map!strip
				.map!(line => (line.length > 1 && line[0] == '.' && line[1] == '.') ? line.count(' ') : 0)
				.sum;
		
		entries.length = countEntries + 1;
		
		allCommands.length = countCommands + 1;
		allInformation.length = countInformation + 1;
		allInformationCommands.length = countInformationCommands + 1;
		
		allArgsCommands.length = countArgsCommand + 1;
		allArgsInformation.length = countArgsInformation + 1;
		allArgsInformationCommands.length = countArgsInformationCommand + 1;
		
		Entry!String* entry;
		
		size_t offsetEntry, offsetCommand, offsetInformation, offsetInformationCommand,
			offsetCommandArg, offsetInformationArg, offsetInformationCommandArg;
		
		foreach(line; sourceText.lineSplitter) {
			line = line.strip;
			
			if (line.length > 0) {
				uint idx;
				bool lastWasCommand, lastWasInformationCommand;
				
				foreach(v; line.splitter(' ')) {
					if (idx == 0) {
						if (v[0] == '.' && (v.length > 1 && v[1] == '.')) {
							lastWasCommand = false;
							lastWasInformationCommand = true;
							// ..

							if (entry !is null && entry.information.length > 0 && entry.information[$-1].commands.length > 0) {
								offsetInformationCommandArg += entry.information[$-1].commands[$-1].args.length;
							}

							if (entry.information[$-1].commands is null) {
								entry.information[$-1].commands = allInformationCommands[offsetInformationCommand .. offsetInformationCommand + 1];
							} else {
								entry.information[$-1].commands = allInformationCommands[offsetInformationCommand .. offsetInformationCommand + entry.information[$-1].commands.length + 1];
							}

							entry.information[$-1].commands[$-1].name = v[2 .. $];
						} else if (v[0] == '.') {
							lastWasCommand = true;
							lastWasInformationCommand = false;

							if (v.length > 2 && v[1] == '\\' && v[2] == '.') {
								(cast(char[])v)[1] = '.'; // .\. -> ...<token> <token ...>
								v = v[1 .. $]; // -> ..<token> <token ...>
							}

							if (entry !is null && entry.commands.length > 0) {
								offsetCommandArg++;
							}

							if (v.length == resetCommand.length + 1 && v[1 .. $] == resetCommand) {
								if (entry !is null) {
									foreach(cmd; entry.commands) {
										offsetCommandArg += cmd.args.length;
									}
									
									foreach(info; entry.information) {
										offsetInformationArg += info.args.length;
										offsetInformationCommand += info.commands.length;

										foreach(cmd; info.commands) {
											offsetInformationCommandArg += cmd.args.length;
										}
									}
									
									offsetEntry++;
									offsetInformation += entry.information.length;
									offsetCommand += entry.commands.length;
								}
								
								entry = &entries[offsetEntry];
							}
							
							if (entry.commands is null) {
								entry.commands = allCommands[offsetCommand .. offsetCommand + 1];
							} else {
								entry.commands = allCommands[offsetCommand .. offsetCommand + entry.commands.length + 1];
							}
							
							entry.commands[$-1].name = v[1 .. $];
						} else {
							lastWasCommand = false;
							lastWasInformationCommand = false;
							
							if (v.length > 1 && v[0] == '\\' && v[1] == '.')
								v = v[1 .. $];
							
							if (entry.commands is null) {
								entry.information = allInformation[offsetInformation .. offsetInformation + 1];
							} else {
								entry.information = allInformation[offsetInformation .. offsetInformation + entry.information.length + 1];
							}
							
							entry.information[$-1].name = v;
						}
						
					} else {
						if (lastWasCommand) {
							if (entry.commands[$-1].args is null) {
								entry.commands[$-1].args = allArgsCommands[offsetCommandArg .. offsetCommandArg + 1];
							} else {
								entry.commands[$-1].args = allArgsCommands[offsetCommandArg .. offsetCommandArg + entry.commands[$-1].args.length + 1];
							}
							
							entry.commands[$-1].args[$-1] = v;
						} else if (lastWasInformationCommand) {
							if (entry.information[$-1].commands is null) {
								entry.information[$-1].commands[$-1].args = allArgsInformationCommands[offsetInformationCommandArg .. offsetInformationCommandArg + 1];
							} else {
								entry.information[$-1].commands[$-1].args = allArgsInformationCommands[offsetInformationCommandArg .. offsetInformationCommandArg + entry.information[$-1].commands.length + 1];
							}
							
							entry.information[$-1].commands[$-1].args[$-1] = v;
						} else {
							if (entry.information[$-1].args is null) {
								entry.information[$-1].args = allArgsInformation[offsetInformationArg .. offsetInformationArg + 1];
							} else {
								entry.information[$-1].args = allArgsInformation[offsetInformationArg .. offsetInformationArg + entry.information[$-1].args.length + 1];
							}
							
							entry.information[$-1].args[$-1] = v;
						}
					}
					
					idx++;
				}
			}
		}
		
		entries.length--;
		allCommands.length--;
		allInformation.length--;
		allArgsCommands.length--;
		allArgsInformation.length--;
		allArgsInformationCommands.length--;
	}
	
	@disable
	this(this);
}

///
struct Entry(String) if (isSomeString!String) {
	///
	Item!String[] commands;
	///
	Item!String[] information;
}

///
struct Item(String) if (isSomeString!String) {
	import std.traits : isPointer;
	
	///
	String name;
	///
	String[] args;
	
	Item!String[] commands;
	
	///
	T get(T)(size_t offset, T default_ = T.init) if (!(is(T == struct) || is(T == class) || is(T == union) || isPointer!T)) {
		import std.conv : to;
		if (args.length <= offset) {
			return to!T(args[offset]);
		} else {
			return default_;
		}
	}
}

///
unittest {
	CommandSequenceReader!string reader = CommandSequenceReader!string("
.new

Hi <name>

.new 8
.something back 6

Bye <name> loozer

", "new");
}

unittest {
	CommandSequenceReader!dstring reader = CommandSequenceReader!dstring("
.new

Hi <name>

.new 8
.something back 6

Bye <name> loozer

"d, "new"d);
}

///
unittest {
	CommandSequenceReader!string reader = CommandSequenceReader!string("
.new

Hi <name>

.new 8
.something back 6

Bye <name> loozer
..myend here!

.\\.a command
", "new");
}

///
unittest {
	CommandSequenceReader!string reader = CommandSequenceReader!string("
.new HEADER
.something here

.new
abcd
", "new");

	import std.stdio;
	writeln(reader.entries);
}