package org.parisoft.noop.ui.highlighting

import com.google.inject.Singleton
import org.eclipse.xtext.Action
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ide.editor.syntaxcoloring.IHighlightedPositionAcceptor
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.util.CancelIndicator
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import com.google.inject.Inject
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.noop.Method

@Singleton
class NoopSemanticHighlightingCalculator implements ISemanticHighlightingCalculator {

	@Inject extension Members

	override provideHighlightingFor(XtextResource resource, IHighlightedPositionAcceptor acceptor, CancelIndicator cancelIndicator) {
		val root = resource.getParseResult().getRootNode()

		for (node : root.getAsTreeIterable()) {
			val grammarElement = node.getGrammarElement()

			switch (grammarElement) {
//				ParserRule: {
//					if (grammarElement.name == NoopClass.simpleName && node.semanticElement instanceof NoopClass) {
//						acceptor.addPosition(node.offset, (node.semanticElement as NoopClass).name.length, NoopHighlightingConfiguration.CLASS_ID)
//					}
//				}
				RuleCall: {
					var rule = grammarElement.rule
					val container = grammarElement.eContainer

					if (rule.name == 'ID' && container instanceof Assignment && (container as Assignment).feature == 'name') {
						val element = node.semanticElement
						
						if ((element instanceof Variable && (element as Variable).isStatic) || (element instanceof Method && (element as Method).isStatic)) {
							acceptor.addPosition(node.offset, node.length, NoopHighlightingConfiguration.STRING_ID)
						}
					}
				}
				Action:
					if (node.semanticElement instanceof MemberRef) {
						val ref = node.semanticElement as MemberRef
						val name = ref.member?.name ?: ''

						if (ref.member.isStatic) {
							acceptor.addPosition(node.offset, name.length, NoopHighlightingConfiguration.STRING_ID)
						}
					} else if (node.semanticElement instanceof MemberSelect) {
						val selection = node.semanticElement as MemberSelect
						val name = selection.member?.name ?: ''

						if (selection.member.isStatic) {
							acceptor.addPosition(node.offset + node.text.trim.indexOf(Members::STATIC_PREFIX), name.length,
								NoopHighlightingConfiguration.STRING_ID)
						}
					}
			}
		}
	}

}
