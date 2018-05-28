package org.parisoft.noop.^extension

import org.parisoft.noop.noop.Storage
import org.parisoft.noop.noop.StorageType

class Tags {
	
	def isMapperConfig(Storage tag) {
		tag?.type == StorageType::MMC3CFG
	}
}