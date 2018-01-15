package org.parisoft.noop.ui.contentassist

import org.eclipse.xtext.ui.editor.contentassist.PrefixMatcher

class SmartPrefixMatcher extends PrefixMatcher {
	
	override isCandidateMatchingPrefix(String name, String prefix) {
		val loName = name.toLowerCase
		val chars = prefix.toLowerCase.toCharArray
		var lastIndex = -1
		
		for (c : chars) {
			lastIndex = loName.indexOf(c, lastIndex + 1)
			
			if (lastIndex == -1) {
				return false
			}
		}
		
		true
	}
	
}