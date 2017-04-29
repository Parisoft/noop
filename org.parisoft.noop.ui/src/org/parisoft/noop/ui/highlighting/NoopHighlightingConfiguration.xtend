package org.parisoft.noop.ui.highlighting

import org.eclipse.swt.SWT
import org.eclipse.swt.graphics.RGB
import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultHighlightingConfiguration
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfigurationAcceptor
import org.eclipse.xtext.ui.editor.utils.TextStyle

class NoopHighlightingConfiguration extends DefaultHighlightingConfiguration {
	
	public static val CLASS_ID = 'classId'

	override configure(IHighlightingConfigurationAcceptor acceptor) {
		super.configure(acceptor)
		acceptor.acceptDefaultHighlighting(CLASS_ID, 'Classes and Types', classTextStyle)
	}

	def classTextStyle() {
		val style = new TextStyle
		style.color = new RGB(0, 0, 0)
		style.style = SWT.BOLD
		 
		return style
	}

}
