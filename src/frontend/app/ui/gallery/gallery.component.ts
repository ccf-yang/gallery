import {Component, HostListener, OnDestroy, OnInit, ViewChild} from '@angular/core';
import {AuthenticationService} from '../../model/network/authentication.service';
import {ActivatedRoute, Params, Router} from '@angular/router';
import {ContentService} from './content.service';
import {GalleryGridComponent} from './grid/grid.gallery.component';
import {Config} from '../../../../common/config/public/Config';
import {NavigationService} from '../../model/navigation.service';
import {UserRoles} from '../../../../common/entities/UserDTO';
import {Subscription} from 'rxjs';
import {PageHelper} from '../../model/page.helper';
import {QueryParams} from '../../../../common/QueryParams';
import {GallerySortingService, GroupedDirectoryContent} from './navigator/sorting.service';
import {FilterService} from './filter/filter.service';
import {PiTitleService} from '../../model/pi-title.service';
import {ContentLoaderService} from './contentLoader.service';
import {GalleryLightboxComponent} from './lightbox/lightbox.gallery.component';
import {FrameComponent} from '../frame/frame.component';
import {NgIf} from '@angular/common';
import {GalleryNavigatorComponent} from './navigator/navigator.gallery.component';
import {DirectoriesComponent} from './directories/directories.component';
import {ContentWrapperWithError} from '../../../../common/entities/ContentWrapper';
import {SearchQueryUtils} from '../../../../common/SearchQueryUtils';
import {GalleryService} from './gallery.service';

@Component({
  selector: 'app-gallery',
  templateUrl: './gallery.component.html',
  styleUrls: ['./gallery.component.css'],
  imports: [
    GalleryLightboxComponent,
    FrameComponent,
    NgIf,
    GalleryNavigatorComponent,
    DirectoriesComponent,
    GalleryGridComponent,
  ]
})
export class GalleryComponent implements OnInit, OnDestroy {
  @ViewChild(GalleryGridComponent, {static: false})
  grid: GalleryGridComponent;

  public showSearchBar = false;

  config = Config;
  public directoryContent: GroupedDirectoryContent;
  private subscription: { [key: string]: Subscription } = {
    content: null,
    route: null,
    sorting: null,
  };

  constructor(
    public contentLoader: ContentLoaderService,
    public contentService: ContentService,
    public galleryService: GalleryService,
    private authService: AuthenticationService,
    private router: Router,
    private route: ActivatedRoute,
    private navigation: NavigationService,
    private filterService: FilterService,
    private sortingService: GallerySortingService,
    private piTitleService: PiTitleService,
  ) {
    PageHelper.showScrollY('gallery');
  }

  get ContentWrapper(): ContentWrapperWithError {
    return this.contentLoader.content.value;
  }

  ngOnDestroy(): void {
    if (this.subscription.content !== null) {
      this.subscription.content.unsubscribe();
    }
    if (this.subscription.route !== null) {
      this.subscription.route.unsubscribe();
    }
    if (this.subscription.sorting !== null) {
      this.subscription.sorting.unsubscribe();
    }
  }

  async ngOnInit(): Promise<boolean> {
    if (!this.authService.isAuthenticated()) {
      return this.navigation.toLogin();
    }
    this.showSearchBar = this.authService.canSearch();
    this.subscription.content = this.contentService.sortedFilteredContent
      .subscribe((dc: GroupedDirectoryContent) => {
        this.onContentChange(dc);
      });
    this.subscription.route = this.route.params.subscribe(this.onRoute);
  }

  private onRoute = async (params: Params): Promise<void> => {
    const searchQuery = SearchQueryUtils.parseURLifiedQuery(params[QueryParams.gallery.search.query]);
    if (searchQuery) {
      this.contentLoader.search(searchQuery).catch(console.error);
      this.piTitleService.setSearchTitle(searchQuery);
      return;
    }

    let directoryName = params[QueryParams.gallery.directory];
    directoryName = directoryName || '';

    this.piTitleService.setDirectoryTitle(directoryName);
    this.contentLoader.loadDirectory(directoryName);
  };

  private onContentChange = (content: GroupedDirectoryContent): void => {
    if (!content) {
      return;
    }
    this.directoryContent = content;

    // enforce change detection on grid
    this.directoryContent.mediaGroups = this.directoryContent.mediaGroups?.slice();
  };

}
