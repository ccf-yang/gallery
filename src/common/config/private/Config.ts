import {PrivateConfigClass} from './PrivateConfigClass';
import {ConfigClassBuilder} from 'typeconfig/node';
import {ProjectPath} from '../../../backend/ProjectPath';

// pre-load config to know the media/temp folder locations
const pre = ConfigClassBuilder.attachPrivateInterface(new PrivateConfigClass());
try {
  pre.loadSync({preventSaving: true});
} catch (e) { /* empty */
  console.error(e);
}
ProjectPath.init(pre);

export const Config = ConfigClassBuilder.attachPrivateInterface(new PrivateConfigClass());
try {
  // load twice: the first call makes sure the config file exists on disk
  Config.loadSync();
  Config.loadSync();
} catch (e) {
  console.error('[Config] Error during loading config. Reverting to defaults.');
  console.error(e);
}
// set actual config
ProjectPath.init(Config);
