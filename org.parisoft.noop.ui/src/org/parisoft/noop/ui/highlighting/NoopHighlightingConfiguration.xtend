package org.parisoft.noop.ui.highlighting

import org.eclipse.swt.SWT
import org.eclipse.swt.graphics.RGB
import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultHighlightingConfiguration
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfigurationAcceptor

class NoopHighlightingConfiguration extends DefaultHighlightingConfiguration {

	public static val CLASS_ID = 'classId'
	public static val TAG_ID = 'tagId'
	public static val ASM_ID = 'asmId'
	public static val BOOL_ID = 'boolId'
	public static val FIELD_ID = 'fieldId'
	public static val FIELD_STATIC_ID = 'fieldStaticId'
	public static val FIELD_CONST_ID = 'fieldConstId'
	public static val VARIABLE_ID = 'variableId'
	public static val METHOD_STATIC_ID = 'methodStaticId'

	override configure(IHighlightingConfigurationAcceptor acceptor) {
		super.configure(acceptor)
		acceptor.acceptDefaultHighlighting(ASM_ID, 'ASM native code', asmTextStyle)
		acceptor.acceptDefaultHighlighting(BOOL_ID, 'Bool', boolTextStyle)
		acceptor.acceptDefaultHighlighting(CLASS_ID, 'Classes and Types', classTextStyle)
		acceptor.acceptDefaultHighlighting(FIELD_CONST_ID, 'Constant Fields', constantFieldTextStyle)
		acceptor.acceptDefaultHighlighting(FIELD_ID, 'Fields', fieldTextStyle)
		acceptor.acceptDefaultHighlighting(FIELD_STATIC_ID, 'Static Fields', staticFieldTextStyle)
		acceptor.acceptDefaultHighlighting(METHOD_STATIC_ID, 'Static Methods', staticMethodTextStyle)
		acceptor.acceptDefaultHighlighting(TAG_ID, 'Tags', tagTextStyle)
		acceptor.acceptDefaultHighlighting(VARIABLE_ID, 'Variables', variableTextStyle)
	}

	def asmTextStyle() {
		defaultTextStyle.copy => [
			color = new RGB(255, 255, 255)
			backgroundColor = new RGB(77, 77, 77)
		]
	}

	def boolTextStyle() {
		numberTextStyle.copy => [
			style = SWT::BOLD
		]
	}

	def classTextStyle() {
		defaultTextStyle.copy => [
			color = new RGB(0, 0, 0)
			style = SWT.BOLD
		]
	}

	override commentTextStyle() {
		defaultTextStyle.copy => [
			color = new RGB(125, 125, 125)
			style = SWT::ITALIC
		]
	}

	def constantFieldTextStyle() {
		staticFieldTextStyle.copy => [
			style = style.bitwiseOr(SWT::BOLD)
		]
	}

	def fieldTextStyle() {
		defaultTextStyle.copy => [
			color = new RGB(130, 70, 15)
		]
	}

	override keywordTextStyle() {
		super.keywordTextStyle() => [
			color = new RGB(120, 0, 0)
		]
	}

	override numberTextStyle() {
		super.numberTextStyle() => [
			color = new RGB(0, 0, 255)
		]
	}

	def staticFieldTextStyle() {
		fieldTextStyle.copy => [
			style = SWT::ITALIC
		]
	}

	def staticMethodTextStyle() {
		defaultTextStyle.copy => [
			style = SWT::ITALIC
		]
	}

	override stringTextStyle() {
		numberTextStyle.copy => [
			style = SWT::BOLD
		]
	}

	def tagTextStyle() {
		commentTextStyle.copy
	}

	def variableTextStyle() {
		defaultTextStyle.copy
	}
}
