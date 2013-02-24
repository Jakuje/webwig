-- Wherigo.ZCommand

table = {
	Text = 'Text command',
	CmdWith = true,
	EmptyTargetListText = 'Empty target list text',
	MakeReciprocal = false,
	WorksWithAll = false,
	WorksWithList = {}, -- to test with Zcharacter, ZItem
	Enabled = false
}

command = Wherigo.ZCommand(table);
assert(command.Text == table.Text, "Problem with Text")
assert(command.CmdWith == table.CmdWith, "Problem with CmdWith")
assert(command.EmptyTargetListText == table.EmptyTargetListText, "Problem with EmptyTargetListText")
assert(command.MakeReciprocal == table.MakeReciprocal, "Problem with MakeReciprocal")
assert(command.WorksWithAll == table.WorksWithAll, "Problem with WorksWithAll")
assert(command.WorksWithList == table.WorksWithList, "Problem with WorksWithList")
assert(command.Enabled == table.Enabled, "Problem with Enabled")


command = Wherigo.ZCommand.new(table);
assert(command.Text == table.Text, "Problem with Text")
assert(command.CmdWith == table.CmdWith, "Problem with CmdWith")
assert(command.EmptyTargetListText == table.EmptyTargetListText, "Problem with EmptyTargetListText")
assert(command.MakeReciprocal == table.MakeReciprocal, "Problem with MakeReciprocal")
assert(command.WorksWithAll == table.WorksWithAll, "Problem with WorksWithAll")
assert(command.WorksWithList == table.WorksWithList, "Problem with WorksWithList")
assert(command.Enabled == table.Enabled, "Problem with Enabled")

print(command)
