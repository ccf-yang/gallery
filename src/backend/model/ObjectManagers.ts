/* eslint-disable @typescript-eslint/no-var-requires */
import {SQLConnection} from './database/SQLConnection';
import {Logger} from '../Logger';
import {JobManager} from './jobs/JobManager';
import {DirectoryPathDTO, ParentDirectoryDTO} from '../../common/entities/DirectoryDTO';
import {GalleryManager} from './database/GalleryManager';
import {UserManager} from './database/UserManager';
import {IndexingManager} from './database/IndexingManager';
import {SearchManager} from './database/SearchManager';
import {VersionManager} from './database/VersionManager';
import {CoverManager} from './database/CoverManager';
import {AlbumManager} from './database/AlbumManager';
import {IObjectManager} from './database/IObjectManager';
import {ProjectedCacheManager} from './database/ProjectedCacheManager';
import {SessionManager} from './database/SessionManager';

const LOG_TAG = '[ObjectManagers]';

export class ObjectManagers {

  private static instance: ObjectManagers = null;

  private readonly managers: IObjectManager[];
  private galleryManager: GalleryManager;
  private userManager: UserManager;
  private searchManager: SearchManager;
  private indexingManager: IndexingManager;
  private coverManager: CoverManager;
  private versionManager: VersionManager;
  private jobManager: JobManager;
  private albumManager: AlbumManager;
  private projectedCacheManager: ProjectedCacheManager;
  private sessionManager: SessionManager;
  private initDone = false;

  constructor() {
    this.managers = [];
  }

  public static getInstance(): ObjectManagers {
    if (!this.instance) {
      this.instance = new ObjectManagers();
    }
    return this.instance;
  }

  public static async reset(): Promise<void> {
    Logger.silly(LOG_TAG, 'Object manager reset begin');
    if (ObjectManagers.isReady()) {
      if (
        ObjectManagers.getInstance().IndexingManager &&
        ObjectManagers.getInstance().IndexingManager.IsSavingInProgress
      ) {
        await ObjectManagers.getInstance().IndexingManager.SavingReady;
      }
      for (const manager of ObjectManagers.getInstance().managers) {
        if (manager === ObjectManagers.getInstance().versionManager) {
          continue;
        }
        if (manager.cleanUp) {
          await manager.cleanUp();
        }
      }
    }

    await SQLConnection.close();
    this.instance = null;
    Logger.debug(LOG_TAG, 'Object manager reset done');
  }

  public static isReady(): boolean {
    return this.instance && this.instance.initDone;
  }


  public async init(): Promise<void> {
    if (this.initDone) {
      return;
    }
    await SQLConnection.init();
    await this.initManagers();
    Logger.debug(LOG_TAG, 'SQL DB inited');
    this.initDone = true;
  }

  private async initManagers(): Promise<void> {
    this.AlbumManager = new AlbumManager();
    this.GalleryManager = new GalleryManager();
    this.IndexingManager = new IndexingManager();
    this.CoverManager = new CoverManager();
    this.SearchManager = new SearchManager();
    this.UserManager = new UserManager();
    this.VersionManager = new VersionManager();
    this.JobManager = new JobManager();
    this.ProjectedCacheManager = new ProjectedCacheManager();
    this.SessionManager = new SessionManager();

    for (const manager of ObjectManagers.getInstance().managers) {
      if (manager === ObjectManagers.getInstance().versionManager) {
        continue;
      }
      if (manager.init) {
        await manager.init();
      }
    }
  }

  public async onDataChange(
    changedDir: DirectoryPathDTO = null
  ): Promise<void> {
    await this.VersionManager.onNewDataVersion();

    for (const manager of this.managers) {
      if (manager === this.versionManager) {
        continue;
      }
      if (manager.onNewDataVersion) {
        await manager.onNewDataVersion(changedDir);
      }
    }
  }


  get VersionManager(): VersionManager {
    return this.versionManager;
  }

  set VersionManager(value: VersionManager) {
    if (this.versionManager) {
      this.managers.splice(this.managers.indexOf(this.versionManager), 1);
    }
    this.versionManager = value;
    this.managers.push(this.versionManager);
  }

  get AlbumManager(): AlbumManager {
    return this.albumManager;
  }

  set AlbumManager(value: AlbumManager) {
    if (this.albumManager) {
      this.managers.splice(this.managers.indexOf(this.albumManager), 1);
    }
    this.albumManager = value;
    this.managers.push(this.albumManager);
  }

  get CoverManager(): CoverManager {
    return this.coverManager;
  }

  set CoverManager(value: CoverManager) {
    if (this.coverManager) {
      this.managers.splice(this.managers.indexOf(this.coverManager as IObjectManager), 1);
    }
    this.coverManager = value;
    this.managers.push(this.coverManager as IObjectManager);
  }

  get IndexingManager(): IndexingManager {
    return this.indexingManager;
  }

  set IndexingManager(value: IndexingManager) {
    if (this.indexingManager) {
      this.managers.splice(this.managers.indexOf(this.indexingManager as IObjectManager), 1);
    }
    this.indexingManager = value;
    this.managers.push(this.indexingManager as IObjectManager);
  }

  get GalleryManager(): GalleryManager {
    return this.galleryManager;
  }

  set GalleryManager(value: GalleryManager) {
    if (this.galleryManager) {
      this.managers.splice(this.managers.indexOf(this.galleryManager as IObjectManager), 1);
    }
    this.galleryManager = value;
    this.managers.push(this.galleryManager as IObjectManager);
  }

  get UserManager(): UserManager {
    return this.userManager;
  }

  set UserManager(value: UserManager) {
    if (this.userManager) {
      this.managers.splice(this.managers.indexOf(this.userManager as IObjectManager), 1);
    }
    this.userManager = value;
    this.managers.push(this.userManager as IObjectManager);
  }

  get SearchManager(): SearchManager {
    return this.searchManager;
  }

  set SearchManager(value: SearchManager) {
    if (this.searchManager) {
      this.managers.splice(this.managers.indexOf(this.searchManager as IObjectManager), 1);
    }
    this.searchManager = value;
    this.managers.push(this.searchManager as IObjectManager);
  }

  get JobManager(): JobManager {
    return this.jobManager;
  }

  set JobManager(value: JobManager) {
    if (this.jobManager) {
      this.managers.splice(this.managers.indexOf(this.jobManager as IObjectManager), 1);
    }
    this.jobManager = value;
    this.managers.push(this.jobManager as IObjectManager);
  }

  get ProjectedCacheManager(): ProjectedCacheManager {
    return this.projectedCacheManager;
  }

  set ProjectedCacheManager(value: ProjectedCacheManager) {
    if (this.projectedCacheManager) {
      this.managers.splice(this.managers.indexOf(this.projectedCacheManager as IObjectManager), 1);
    }
    this.projectedCacheManager = value;
    this.managers.push(this.projectedCacheManager as IObjectManager);
  }
  get SessionManager(): SessionManager {
    return this.sessionManager;
  }

  set SessionManager(value: SessionManager) {
    if (this.sessionManager) {
      this.managers.splice(this.managers.indexOf(this.sessionManager as IObjectManager), 1);
    }
    this.sessionManager = value;
    this.managers.push(this.sessionManager as IObjectManager);
  }

}
