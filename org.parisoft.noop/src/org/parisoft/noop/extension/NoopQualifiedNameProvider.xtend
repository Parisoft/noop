package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.util.IResourceScopeCache
import org.eclipse.xtext.util.Tuples
import org.parisoft.noop.noop.ElseStatement
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.ForeverStatement
import org.parisoft.noop.noop.IfStatement
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopPackage

import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.NoopClass
import com.google.common.base.CharMatcher

class NoopQualifiedNameProvider extends DefaultDeclarativeQualifiedNameProvider {

	@Inject IResourceScopeCache cache = IResourceScopeCache.NullImpl::INSTANCE;

	@Inject extension TypeSystem

	override getFullyQualifiedName(EObject obj) {
		if (obj === null) {
			return null
		}
		
		obj.fullyQualifiedNameFor ?: if (obj?.eIsProxy) {
			obj.resolve?.fullyQualifiedNameFor
		}
	}

	private def dispatch getFullyQualifiedNameFor(EObject o) {
		super.getFullyQualifiedName(o)
	}

	private def dispatch getFullyQualifiedNameFor(ForStatement obj) {
		obj.getFullyQualifiedNameFor(ForStatement)
	}

	private def dispatch getFullyQualifiedNameFor(ForeverStatement obj) {
		obj.getFullyQualifiedNameFor(ForeverStatement)
	}

	private def dispatch getFullyQualifiedNameFor(IfStatement obj) {
		obj.getFullyQualifiedNameFor(IfStatement)
	}

	private def dispatch getFullyQualifiedNameFor(ElseStatement obj) {
		obj.getFullyQualifiedNameFor(ElseStatement)
	}

	private def <T extends EObject> getFullyQualifiedNameFor(EObject obj, Class<T> type) {
		cache.get(Tuples::pair(obj, "fqn"), obj.eResource, [
			val name = resolver.apply(obj)

			if (name.nullOrEmpty) {
				return null
			}

			val method = obj.getContainerOfType(Method)
			val n = method.getAllContentsOfType(type).takeWhile[it != obj].size.toString
			val objName = converter.toQualifiedName(name.concat(n))
			val metName = method.fullyQualifiedName

			metName.append(objName)
		])
	}

	private def dispatch getFullyQualifiedNameFor(Method m) {
		cache.get(Tuples::pair(m, "fqn"), m.eResource, [
			val name = resolver.apply(m)

			if (name.nullOrEmpty) {
				return null
			}

			var params = NodeModelUtils::findNodesForFeature(m, NoopPackage.Literals::METHOD__PARAMS).map [
				val text = it.text.trim
				val idx = text.indexOf('[')

				if (idx != -1) {
					val d = CharMatcher::is('[').countIn(text)

					if (d == 1) {
						text.substring(0, idx).concat('Array')
					} else if (d == 2) {
						text.substring(0, idx).concat('Matrix')
					} else {
						text.substring(0, idx).concat(d.toString).concat('D')
					}
				} else {
					text.substring(0, text.indexOf(' '))
				}
			].join('_')

			if (!params.nullOrEmpty) {
				params = '_' + params
			}

			val metName = converter.toQualifiedName(name.concat(params))
			val clsName = m.getContainerOfType(NoopClass).fullyQualifiedName

			clsName.append(metName)
		])
	}
}
