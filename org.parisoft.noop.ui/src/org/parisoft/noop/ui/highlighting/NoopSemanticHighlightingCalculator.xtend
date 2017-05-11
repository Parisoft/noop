package org.parisoft.noop.ui.highlighting

import com.google.inject.Singleton
import org.eclipse.xtext.Action
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ide.editor.syntaxcoloring.IHighlightedPositionAcceptor
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.util.CancelIndicator
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
import org.parisoft.noop.^extension.Members

@Singleton
class NoopSemanticHighlightingCalculator implements ISemanticHighlightingCalculator {

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
						val parent = node.parent

						if (parent !== null && parent.grammarElement instanceof RuleCall) {
							rule = (parent.grammarElement as RuleCall).rule

							if (rule.name == 'Variable' && node.text.startsWith(Members::CONSTANT_SUFFIX)) {
								acceptor.addPosition(node.offset, node.length, NoopHighlightingConfiguration.STRING_ID)
							}
						}
					}
				}
				Action:
					if (node.semanticElement instanceof MemberRef) {
						val ref = node.semanticElement as MemberRef
						val name = ref.member?.name ?: ""

						if (name.startsWith(Members::CONSTANT_SUFFIX)) {
							acceptor.addPosition(node.offset, node.length, NoopHighlightingConfiguration.STRING_ID)
						}
					} else if (node.semanticElement instanceof MemberSelection) {
						val selection = node.semanticElement as MemberSelection
						val name = selection.member?.name ?: ""

						if (!selection.isMethodInvocation && name.startsWith(Members::CONSTANT_SUFFIX)) {
							acceptor.addPosition(node.endOffset - name.length, name.length, NoopHighlightingConfiguration.STRING_ID)
						}
					}
			}
		}
	}

}
