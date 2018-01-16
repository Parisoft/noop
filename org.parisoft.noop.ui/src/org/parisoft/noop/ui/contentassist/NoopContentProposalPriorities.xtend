package org.parisoft.noop.ui.contentassist

import org.eclipse.xtext.ui.editor.contentassist.ContentProposalPriorities
import org.eclipse.xtend.lib.annotations.Accessors

class NoopContentProposalPriorities extends ContentProposalPriorities {
	
	@Accessors val crossReferencePriority = 200//500;
	@Accessors val keywordPriority = 700//300;
	@Accessors val defaultPriority = 100//400;
}