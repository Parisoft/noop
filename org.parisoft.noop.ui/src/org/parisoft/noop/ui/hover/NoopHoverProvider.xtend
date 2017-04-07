package org.parisoft.noop.ui.hover

import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider
import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.noop.Variable

class NoopHoverProvider extends DefaultEObjectHoverProvider {
	
	override protected getFirstLine(EObject o) {
		if (o instanceof Variable) {
			return '''Field <b>«o.name»</b>. TODO: differ filed from variable'''
		}
		super.getFirstLine(o)
	}
	
}