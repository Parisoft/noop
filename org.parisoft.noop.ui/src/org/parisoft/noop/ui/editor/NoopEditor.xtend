package org.parisoft.noop.ui.editor

import org.eclipse.ui.part.FileEditorInput
import org.eclipse.xtext.ui.editor.XtextEditor

class NoopEditor extends XtextEditor {

	def getFile() {
		if (editorInput instanceof FileEditorInput) {
			(editorInput as FileEditorInput).file
		}
	}	
}