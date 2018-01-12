package org.parisoft.noop.ui.build

import java.io.PrintStream
import java.util.List
import java.util.Map
import org.eclipse.core.resources.IMarker
import org.eclipse.core.runtime.CoreException
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.xtext.builder.BuilderParticipant
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2
import org.eclipse.xtext.generator.OutputConfiguration
import org.eclipse.xtext.resource.IResourceDescription.Delta
import org.parisoft.noop.generator.Asm8
import utils.Consoles

import static org.parisoft.noop.generator.Asm8.*

class NoopBuildParticipant extends BuilderParticipant {

	new() {
		Consoles::instance => [
			Asm8.outStream = new PrintStream(Consoles::defaultOutputStream, true)
			Asm8.errStream = new PrintStream(Consoles::defaultErrorStream, true)
		]
	}

	override protected doBuild(List<Delta> deltas, Map<String, OutputConfiguration> outputConfigurations,
		Map<OutputConfiguration, Iterable<IMarker>> generatorMarkers, IBuildContext context,
		EclipseResourceFileSystemAccess2 access, IProgressMonitor progressMonitor) throws CoreException {
		if (deltas.forall[shouldGenerate(context.resourceSet.getResource(uri, true), context)]) {
			super.doBuild(deltas, outputConfigurations, generatorMarkers, context, access, progressMonitor)
		}
	}

}
