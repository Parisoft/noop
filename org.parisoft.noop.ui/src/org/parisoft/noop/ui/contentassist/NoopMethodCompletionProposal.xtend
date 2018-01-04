package org.parisoft.noop.ui.contentassist

import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import org.apache.log4j.Logger
import org.eclipse.jface.text.BadLocationException
import org.eclipse.jface.text.IDocument
import org.eclipse.jface.text.ITextViewer
import org.eclipse.jface.text.contentassist.IContextInformation
import org.eclipse.jface.text.link.LinkedModeModel
import org.eclipse.jface.text.link.LinkedModeUI
import org.eclipse.jface.text.link.LinkedPosition
import org.eclipse.jface.text.link.LinkedPositionGroup
import org.eclipse.jface.viewers.StyledString
import org.eclipse.swt.graphics.Image
import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.noop.Storage
import java.util.function.Function
import org.parisoft.noop.noop.Expression
import org.eclipse.xtext.EcoreUtil2
import org.parisoft.noop.noop.NoopClass

class NoopMethodCompletionProposal extends ConfigurableCompletionProposal {

	static val Logger log = Logger::getLogger(NoopMethodCompletionProposal);
	static val LINKED_MODE_INVOCATION = 1
	static val LINKED_MODE_OVERRIDE = 2

	var ITextViewer viewer
	var List<Variable> params
	var mode = 0

	new(String replacementString, int replacementOffset, int replacementLength, int cursorPosition, Image image,
		StyledString displayString, IContextInformation contextInformation, String additionalProposalInfo) {
		super(replacementString, replacementOffset, replacementLength, cursorPosition, image, displayString,
			contextInformation, additionalProposalInfo)
	}

	def setLinkedModeForInvocation(ITextViewer viewer, Method method) {
		this.params = method.params.toList

		if (params.size > 0) {
			super.setSimpleLinkedMode(viewer)
			this.viewer = viewer
			this.mode = LINKED_MODE_INVOCATION

			val paramNames = params.map[name].join(', ')
			replacementString = '''«replacementString»(«paramNames»)'''
			replacementLength = replacementLength + paramNames.length + 2
			cursorPosition = cursorPosition + 1
			selectionStart = replacementOffset + cursorPosition
			selectionLength = params.head.name.length
		}
	}

	def setLinkedModeForOverride(ITextViewer viewer, Method method, boolean isStatic,
		extension Function<Expression, Object> valueOf) {
		super.setSimpleLinkedMode(viewer)
		this.viewer = viewer
		this.params = method.params.toList
		this.mode = LINKED_MODE_OVERRIDE

		val paramsString = params.map [
			'''«type.name»«dimension.map['''[«value?.apply»]'''].join» «name»«storage.toProposalString(valueOf)»'''
		].join(', ')
		val receiver = if(isStatic) EcoreUtil2::getContainerOfType(method, NoopClass).name else 'super'
		val methodTop = '''(«paramsString»)«method.storage.toProposalString(valueOf)» {«System::lineSeparator»'''
		val methodMid = '''		return «receiver».«method.name»«IF method.params.size > 0»(«method.params.map[name].join(', ')»)«ENDIF»'''
		val methodBot = '''«System::lineSeparator»	}'''

		replacementString = replacementString + methodTop + methodMid + methodBot
		replacementLength = replacementLength + methodTop.length + methodMid.length + methodBot.length
		selectionStart = replacementOffset + cursorPosition + methodTop.length + 2
		selectionLength = methodMid.length - 2
		cursorPosition = cursorPosition + methodTop.length + methodMid.length + methodBot.length
	}

	private def toProposalString(Storage storage, extension Function<Expression, Object> valueOf) {
		if (storage !== null) {
			'''«noop» «storage.type.literal»«IF storage.location !== null»[«storage.location.apply»]«ENDIF»'''
		}
	}

	private def void noop() {
	}

	override protected setUpLinkedMode(IDocument document) {
		try {
			if (mode == LINKED_MODE_INVOCATION) {
				val model = new LinkedModeModel()
				val start = new AtomicInteger(selectionStart)

				params.forEach [ param |
					val len = param.name.length
					val ini = start.getAndAdd(len + 2)
					val position = new LinkedPosition(document, ini, len, LinkedPositionGroup::NO_STOP)
					val group = new LinkedPositionGroup
					group.addPosition(position)
					model.addGroup(group)
				]

				model.forceInstall

				val ui = new LinkedModeUI(model, viewer)
				ui.setExitPosition(viewer, start.get - 1, 0, Integer::MAX_VALUE)
				ui.setCyclingMode(LinkedModeUI::CYCLE_ALWAYS)
				ui.enter()
			} else {
				super.setUpLinkedMode(document)
			}
		} catch (BadLocationException e) {
			log.info(e.getMessage(), e)
		}
	}

}
