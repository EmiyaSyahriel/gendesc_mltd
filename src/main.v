module main
import os

fn main() {
	args := arguments()
	mut section := ""
	mut copy := false
	mut gds := GendescApp{}

	if args.len == 1
	{
		println('Usage :  ${args[0]} [section]

		Make sure there is desc.toml in current directory'
		.replace('\t', '')
		)
		exit(0)
		return
	}

	// println("Arguments:")
	for arg in args
	{
		// println("\t- [${i}] ${arg}")
		if arg == "-v"
		{
			gds.verbose = true
		}
		else if arg == "-c"
		{
			copy = true
		}
		else 
		{
			section = arg
		}
	}

	gds.exe_dir = os.abs_path(os.join_path(os.executable(), ".."))
	gds.process()
	gds.present(section, copy)
}