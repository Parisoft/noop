package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.io.File
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.Path
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.resource.XtextResourceSet

class Files {
	
	public static val RES_FOLDER = 'res'
	
	@Inject XtextResourceSet resourceSet

	def toFile(URI uri) {
		if (uri.isPlatform) {
			new File(ResourcesPlugin.workspace.root.getFile(new Path(uri.toPlatformString(true))).rawLocation.toOSString)
		} else {
			new File(resourceSet.getResource(uri, true).resourceSet.URIConverter.normalize(uri).toFileString)
		}
	}
	
	def getResFolder(URI uri) {
		uri.projectURI.appendSegment(RES_FOLDER).toFile
	}
	
	def getProjectURI(URI uri) {
		uri.trimSegments(uri.segmentCount - 2)
	}
}