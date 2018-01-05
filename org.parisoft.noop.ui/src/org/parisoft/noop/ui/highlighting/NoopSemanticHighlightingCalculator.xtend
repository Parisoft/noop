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
import org.parisoft.noop.noop.Member

@Singleton
class NoopSemanticHighlightingCalculator implements ISemanticHighlightingCalculator {

	@Inject extension Members

	override provideHighlightingFor(XtextResource resource, IHighlightedPositionAcceptor acceptor,
		CancelIndicator cancelIndicator) {
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

					if (rule.name == 'ID' && container instanceof Assignment &&
						(container as Assignment).feature == 'name') {
						val element = node.semanticElement

						if (element instanceof Member) {
							element.colorize(acceptor, node.offset, node.length)
						}
					}
				}
				Action:
					if (node.semanticElement instanceof MemberRef) {
						val ref = node.semanticElement as MemberRef
						val name = ref.member?.name ?: ''

						ref.member.colorize(acceptor, node.offset, name.length)
					} else if (node.semanticElement instanceof MemberSelect) {
						val selection = node.semanticElement as MemberSelect
						val name = selection.member?.name
						val length = name?.length
						val text = node.text.trim
						var i = -1
						
						while(length > 0 && (i = text.indexOf(name, i + 1)) > -1){
							selection.member.colorize(acceptor, node.offset + i, length)
						}
					}
			}
		}
	}

	private def colorize(Member member, IHighlightedPositionAcceptor acceptor, int offset, int length) {
		if (member instanceof Variable) {
			if (member.isField) {
				if (member.isStatic) {
					if (member.isConstant) {
						acceptor.addPosition(offset, length, NoopHighlightingConfiguration::FIELD_CONST_ID)
					} else {
						acceptor.addPosition(offset, length, NoopHighlightingConfiguration::FIELD_STATIC_ID)
					}
				} else {
					acceptor.addPosition(offset, length, NoopHighlightingConfiguration::FIELD_ID)
				}
			}
		} else if (member instanceof Method && (member as Method).isStatic) {
			acceptor.addPosition(offset, length, NoopHighlightingConfiguration::METHOD_STATIC_ID)
		}
	}
}
