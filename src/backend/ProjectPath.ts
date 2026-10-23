import * as path from 'path';
import * as fs from 'fs';
import {PrivateConfigClass} from '../common/config/private/PrivateConfigClass';

export class ProjectPathClass {
  public Root: string;
  public ImageFolder: string;
  public TempFolder: string;
  public TranscodedFolder: string;
  public FrontendFolder: string;
  public DBFolder: string;
  private cfg: PrivateConfigClass;

  init(cfg: PrivateConfigClass) {
    this.cfg = cfg;
    this.reset();
  }

  public normalizeRelative(pathStr: string): string {
    return path.join(pathStr, path.sep);
  }

  public getAbsolutePath(pathStr: string): string {
    return path.isAbsolute(pathStr) ? pathStr : path.join(this.Root, pathStr);
  }

  public getRelativePathToImages(pathStr: string): string {
    return path.relative(this.ImageFolder, pathStr);
  }

  reset(): void {
    this.Root = path.join(__dirname, '/../../');
    this.FrontendFolder = path.join(this.Root, 'dist');
    this.ImageFolder = this.getAbsolutePath(this.cfg.Media.folder);
    this.TempFolder = this.getAbsolutePath(this.cfg.Media.tempFolder);
    this.TranscodedFolder = path.join(this.TempFolder, 'tc');
    this.DBFolder = this.getAbsolutePath(this.cfg.Database.dbFolder);

    // create the thumbnail folder if it does not exist
    if (!fs.existsSync(this.TempFolder)) {
      fs.mkdirSync(this.TempFolder);
    }
  }
}

export const ProjectPath = new ProjectPathClass();
