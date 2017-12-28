package org.parisoft.noop.ui.contentassist

import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal
import org.eclipse.swt.graphics.Image
import org.eclipse.jface.viewers.StyledString
import org.eclipse.jface.text.contentassist.IContextInformation
import org.eclipse.jface.text.IDocument
import org.eclipse.jface.text.link.LinkedPositionGroup
import org.eclipse.jface.text.link.LinkedModeModel
import org.eclipse.jface.text.link.LinkedModeUI
import org.eclipse.jface.text.BadLocationException
import org.eclipse.jface.text.ITextViewer
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.jface.text.link.LinkedPosition
import org.apache.log4j.Logger
import org.parisoft.noop.noop.Variable
import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.noop.Method

class NoopMethodCompletionProposal extends ConfigurableCompletionProposal {

	private static final Logger log = Logger::getLogger(NoopMethodCompletionProposal);

	@Accessors ITextViewer viewer
	@Accessors List<Variable> params

	new(String replacementString, int replacementOffset, int replacementLength, int cursorPosition, Image image,
		StyledString displayString, IContextInformation contextInformation, String additionalProposalInfo) {
		super(replacementString, replacementOffset, replacementLength, cursorPosition, image, displayString,
			contextInformation, additionalProposalInfo)
	}

	def setLinkedMode(ITextViewer viewer, Method method) {
		this.params = method.params.toList

		if (params.size > 0) {
			super.setSimpleLinkedMode(viewer)
			this.viewer = viewer

			val paramNames = params.map[name].join(', ')
			replacementString = '''«replacementString»(«paramNames»)'''
			replacementLength = replacementLength + paramNames.length + 2
			cursorPosition = cursorPosition + 1
			selectionStart = replacementOffset + cursorPosition
			selectionLength = params.head.name.length
		}
	}

	override protected setUpLinkedMode(IDocument document) {
		try {
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
		} catch (BadLocationException e) {
			log.info(e.getMessage(), e)
		}
	}

}
