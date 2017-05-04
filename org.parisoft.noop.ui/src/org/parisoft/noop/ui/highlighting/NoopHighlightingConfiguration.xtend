package org.parisoft.noop.ui.highlighting

import org.eclipse.swt.SWT
import org.eclipse.swt.graphics.RGB
import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultHighlightingConfiguration
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfigurationAcceptor

class NoopHighlightingConfiguration extends DefaultHighlightingConfiguration {

	public static val CLASS_ID = 'classId'
	public static val TAG_ID = 'tagId'

	override configure(IHighlightingConfigurationAcceptor acceptor) {
		super.configure(acceptor)
		acceptor.acceptDefaultHighlighting(CLASS_ID, 'Classes and Types', classTextStyle)
		acceptor.acceptDefaultHighlighting(TAG_ID, 'Tags', tagTextStyle)
	}

	def classTextStyle() {
		val textStyle = defaultTextStyle().copy()
		textStyle.color = new RGB(0, 0, 0)
		textStyle.style = SWT.BOLD

		return textStyle
	}

	def tagTextStyle() {
		val textStyle = defaultTextStyle().copy()
		textStyle.color = new RGB(125, 125, 125)
		textStyle.style = SWT.ITALIC
		
		return textStyle;
	}
}
