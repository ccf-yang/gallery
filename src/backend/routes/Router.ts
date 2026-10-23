import {Express} from 'express';
import {PublicRouter} from './PublicRouter';
import {UserRouter} from './UserRouter';
import {GalleryRouter} from './GalleryRouter';
import {AdminRouter} from './admin/AdminRouter';
import {SettingsRouter} from './admin/SettingsRouter';
import {NotificationRouter} from './NotificationRouter';
import {ErrorRouter} from './ErrorRouter';
import {AlbumRouter} from './AlbumRouter';
import {VersionMWs} from '../middlewares/VersionMWs';

export class Router {
  public static route(app: Express): void {
    app.use(VersionMWs.injectAppVersion);
    PublicRouter.route(app);

    AdminRouter.route(app);
    AlbumRouter.route(app);
    GalleryRouter.route(app);
    NotificationRouter.route(app);
    SettingsRouter.route(app);
    UserRouter.route(app);

    ErrorRouter.route(app);
  }
}
