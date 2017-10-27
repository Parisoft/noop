package org.parisoft.noop.ui.wizard

import java.util.ArrayList
import org.parisoft.noop.^extension.Files

class NoopProjectCreator2 extends NoopProjectCreator {
	
	override protected getAllFolders() {
		val folders = new ArrayList(super.getAllFolders())
		folders += Files::RES_FOLDER
		
		return folders
	}
	
}