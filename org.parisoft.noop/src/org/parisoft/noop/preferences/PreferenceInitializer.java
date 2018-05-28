package org.parisoft.noop.preferences;

import org.eclipse.core.runtime.preferences.AbstractPreferenceInitializer;
import org.eclipse.core.runtime.preferences.DefaultScope;
import org.eclipse.core.runtime.preferences.IEclipsePreferences;

/**
 * Class used to initialize default preference values.
 */
public class PreferenceInitializer extends AbstractPreferenceInitializer {

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.eclipse.core.runtime.preferences.AbstractPreferenceInitializer#initializeDefaultPreferences()
	 */
	public void initializeDefaultPreferences() {
		getPreferenceStore().put(NoopPreferences.P_EMULATOR_PATH, "");
		getPreferenceStore().put(NoopPreferences.P_EMULATOR_OPTS, "");
	}

	public static IEclipsePreferences getPreferenceStore() {
		return DefaultScope.INSTANCE.getNode("org.parisoft.noop");
	}
}
