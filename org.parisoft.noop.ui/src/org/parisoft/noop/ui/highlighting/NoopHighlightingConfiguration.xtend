package org.parisoft.noop.ui.highlighting

import org.eclipse.swt.SWT
import org.eclipse.swt.graphics.RGB
import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultHighlightingConfiguration
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfigurationAcceptor

class NoopHighlightingConfiguration extends DefaultHighlightingConfiguration {

	public static val CLASS_ID = 'classId'
	public static val TAG_ID = 'tagId'
	public static val ASM_ID = 'asmId'

	override configure(IHighlightingConfigurationAcceptor acceptor) {
		super.configure(acceptor)
		acceptor.acceptDefaultHighlighting(CLASS_ID, 'Classes and Types', classTextStyle)
		acceptor.acceptDefaultHighlighting(TAG_ID, 'Tags', tagTextStyle)
		acceptor.acceptDefaultHighlighting(ASM_ID, 'ASM native code', asmTextStyle)
	}

	def classTextStyle() {
		defaultTextStyle.copy => [
			color = new RGB(0, 0, 0)
			style = SWT.BOLD
		]
	}

	def tagTextStyle() {
		defaultTextStyle.copy => [
			color = new RGB(125, 125, 125)
			style = SWT.ITALIC
		]
	}

	def asmTextStyle() {
		defaultTextStyle.copy => [
			color = new RGB(255, 255, 255)
			backgroundColor = new RGB(77, 77, 77)
		]
	}

}
