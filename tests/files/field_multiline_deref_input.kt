val workspacePath = cp.workspaceRoots.bind(this, more.xd()).filter { filePath.startsWith(it) }.map { it.toString() }.maxByOrNull(String::length) ?: ""

