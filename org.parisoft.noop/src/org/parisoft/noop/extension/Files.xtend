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
			val path = new Path(uri.toPlatformString(true))
			new File(ResourcesPlugin::workspace.root.getFile(path).rawLocation.toOSString)
		} else
			try {
				new File(resourceSet.getResource(uri, true).resourceSet.URIConverter.normalize(uri).toFileString)
			} catch (Exception e) {
				new File(uri.toFileString)
			}
	}

	def getResFolder(URI uri) {
		uri.projectURI.appendSegment(RES_FOLDER).toFile
	}

	def URI getProjectURI(URI uri) {
		if (uri.isPlatform) {
			uri.trimSegments(uri.segmentCount - 2)
		} else {
			val path = Path::fromOSString(uri.toFileString)
			val file = ResourcesPlugin::workspace.root.getFileForLocation(path)
			val project = file.project
			URI::createURI(project.locationURI.toString)
		}
	}

	def getProject(URI uri) {
		if (uri.isPlatform) {
			val path = new Path(uri.toPlatformString(true))
			ResourcesPlugin::workspace.root.getFile(path)?.project
		} else {
			val path = Path::fromOSString(uri.toFileString)
			ResourcesPlugin::workspace.root.getFileForLocation(path)?.project
		}

	}
}
