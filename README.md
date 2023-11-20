Preface: This file will be ignored by the default
	Three project specification. If you remove the
	config/project file then you will need to remove
	all non-runnable code on the module path.
	(This will be the root of your project without a
	project spec.)
	For most projects, you can safely leave this file
	as it will not get included in the build output.

#Three
Welcome to Three
A Lua framework for writing applications, mainly
	targeting ComputerCraft, + CC:Tweaked.
	No testing for whether Three can be easily
	ported to use outside of CC will be made.

Three is a framework that focuses on three things:
#Loading
Three will load a bunch of modules for you.
	Sound uninteresting? Read on to learn more
	about user-made module definitions, loaders,
	project structuring, compilation, scripting
	and more.
	In short, Three allows the programmer a simple
	way of smashing a bunch of files (which it
	transforms into individual modules based on
	project configs) into a comprehensive program
	structure.
	No more require()'s at the top of each file,
	/unless you want your project to be strict/
	which Three can also provide.

#Lifetime
Three manages startup/shutdown, various states of
	the project, as well as an extensive standard
	library in part focused on the lifecycle of
	events, messages, connections and various
	other state-kept forms of interaction.

#Logging
Three provides a logging framework that lets the
	modules log their creation, startup, user-made
	logs, events, destruction and exiting of the
	project/application.

#How and why
The main reason Three exists is because I found
	myself doing some weird project structures
	when I had no guidelines (or more correct,
	restrictions...).
	This lead to weird circular dependencies,
	as well as wrangling require() everywhere
	depending on what file would start first on
	this particular revision of some program.
	Therefore, I made Three, which not only will
	provide some locking-down structure...
	...but also resolves those weird circular 
	dependencies for you!
	For the more advanced topics, please refer
	to the wiki portion of the github repo.
	(github.com/SuperNicejohn/Three) NOTE:
	Coming soon.

	Three uses various techniques to place
	all of your code on what it calls a 
	"module path". This will on a default 
	project look something like the following:
	"com.mygroup.mynestedgroup.mymodule.*"
	with "*" being functions and values.
