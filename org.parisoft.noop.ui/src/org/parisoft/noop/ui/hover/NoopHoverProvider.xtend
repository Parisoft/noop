package org.parisoft.noop.ui.hover

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.Variable

class NoopHoverProvider extends DefaultEObjectHoverProvider {

	@Inject extension Members

	override protected getFirstLine(EObject o) {
		if(o instanceof Variable) {
			return '''Field <b>«o.name»</b> of type «o.typeOf.name». TODO: differ filed from variable'''
		}

		if(o instanceof Method) {
			return '''Method <b>«o.name»</b> returns «o.typeOf.name».'''
		}

		super.getFirstLine(o)
	}

}
