package org.parisoft.noop.ui.build;

import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.SubMonitor;
import org.eclipse.xtext.builder.IXtextBuilderParticipant.BuildType;
import org.eclipse.xtext.builder.impl.ToBeBuilt;
import org.eclipse.xtext.builder.impl.ToBeBuiltComputer;
import org.eclipse.xtext.builder.impl.XtextBuilder;

import com.google.inject.Inject;
import com.google.inject.Singleton;

@Singleton
@SuppressWarnings({ "restriction" })
public class NoopBuilder extends XtextBuilder {

	@Inject
	private ToBeBuiltComputer toBeBuiltComputer;

	@Override
	protected void doBuild(ToBeBuilt toBeBuilt, IProgressMonitor monitor, BuildType type) throws CoreException {
		if (type == BuildType.INCREMENTAL
				&& (toBeBuilt.getToBeDeleted().size() > 0 || toBeBuilt.getToBeUpdated().size() > 0)) {
			SubMonitor progress = SubMonitor.convert(monitor, 10);
			toBeBuilt = toBeBuiltComputer.updateProject(getProject(), progress.newChild(2));
			super.doBuild(toBeBuilt, progress.newChild(8), BuildType.FULL);
		} else {
			super.doBuild(toBeBuilt, monitor, type);
		}
	}
}
