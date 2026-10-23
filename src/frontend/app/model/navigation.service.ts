import {Injectable} from '@angular/core';

import {IsActiveMatchOptions, Router} from '@angular/router';
import {Config} from '../../../common/config/public/Config';
import {NavigationLinkTypes} from '../../../common/config/public/ClientConfig';

@Injectable()
export class NavigationService {
  constructor(private router: Router) {
  }

  public isLoginPage(): boolean {
    return (
      this.router.isActive('login',
        {paths: 'exact', queryParams: 'exact', fragment: 'ignored', matrixParams: 'ignored'} as IsActiveMatchOptions)
    );
  }


  public isErrorPage(): boolean {
    return (
      this.router.isActive('error',
        {paths: 'exact', queryParams: 'exact', fragment: 'ignored', matrixParams: 'ignored'} as IsActiveMatchOptions)
    );
  }

  public async toLogin(): Promise<boolean> {
    return this.router.navigate(['login']);
  }

  public async toDefault(): Promise<boolean> {
    if (Config.Gallery.NavBar.links && Config.Gallery.NavBar.links.length > 0) {
      switch (Config.Gallery.NavBar.links[0].type) {
        case NavigationLinkTypes.gallery:
          return this.router.navigate(['gallery', '']);
        case NavigationLinkTypes.albums:
          return this.router.navigate(['albums']);
        case NavigationLinkTypes.search:
          return this.router.navigate(['search', JSON.stringify(Config.Gallery.NavBar.links[0].SearchQuery)]);
        default:
          console.error('nowhere to navigate.');
      }
    }

    return this.router.navigate(['gallery', '']);
  }

  public async toGallery(): Promise<boolean> {
    return this.router.navigate(['gallery', '']);
  }

  public async search(searchText: string): Promise<boolean> {
    return this.router.navigate(['search', searchText]);
  }

  public async toError(): Promise<boolean> {
    return this.router.navigate(['error']);
  }
}
