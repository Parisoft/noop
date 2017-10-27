package org.parisoft.noop.ui.wizard

import java.util.ArrayList

class NoopProjectCreator2 extends NoopProjectCreator {
	
	override protected getAllFolders() {
		val folders = new ArrayList(super.getAllFolders())
		folders += 'res'
		
		return folders
	}
	
}