/* eslint-disable @typescript-eslint/no-inferrable-types */
import 'reflect-metadata';
import {GroupByTypes, GroupingMethod, SortByTypes, SortingMethod} from '../../entities/SortingMethods';
import {UserRoles} from '../../entities/UserDTO';
import {ConfigProperty, SubConfigClass} from 'typeconfig/common';
import {SearchQueryDTO} from '../../entities/SearchQueryDTO';
import {DefaultsJobs} from '../../entities/job/JobDTO';
import {GridSizes} from '../../entities/GridSizes';

declare let $localize: (s: TemplateStringsArray) => string;
if (typeof $localize === 'undefined') {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  global.$localize = (s) => s[0];
}



export enum ConfigPriority {
  basic = 1, advanced, underTheHood
}


export enum ThemeModes {
  light = 1, dark, auto
}

export enum ScrollUpModes {
  never = 1, mobileOnly, always
}

/**
 * Used for lightbox titles
 */
export enum LightBoxTitleTexts {
  NONE = 1,
  file,
  resolution,
  size,

  caption,
  title,

  keywords,
  date,

  camera,
  lens,
  iso,
  fstop,
  focal_length,
  directory,
  titleOrCaption,
  titleOrDirectory,
  titleOrCaptionOrDirectory

}

export type TAGS = {
  client?: true,
  priority?: ConfigPriority,
  name?: string,
  relevant?: (c: any) => boolean,
  dockerSensitive?: boolean,
  hint?: string, // UI hint
  githubIssue?: number,
  secret?: boolean, // these config properties should never travel out of the server
  experimental?: boolean, // is it a beta feature?
  unit?: string, // Unit info to display on UI
  uiIcon?: string,
  uiType?: 'SearchQuery' | 'ThemeSelector' | 'SelectedThemeSettings' | 'SVGIconConfig', // Hint for the UI about the type
  uiOptions?: (string | number)[], //Hint for the UI about the recommended options
  uiAllowSpaces?: boolean
  uiOptional?: boolean; //makes the tag not "required"
  uiDisabled?: (subConfig: any, config: ClientConfig) => boolean
  uiJob?: {
    job: string,
    hideProgress: boolean,
    relevant?: (c: ClientConfig) => boolean,
    description: string
  }[],
  uiResetNeeded?: {
    server?: boolean,
    db?: boolean
  }
};

@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class AutoCompleteItemsPerCategoryConfig {
  @ConfigProperty({
    type: 'unsignedInt',
    tags:
      {
        name: $localize`Maximum items`,
        priority: ConfigPriority.underTheHood
      },
    description: $localize`Maximum number autocomplete items shown at once. If there is not enough items to reach this value, it takes up to double of the individual items.`
  })
  maxItems: number = 20;

  @ConfigProperty({
    type: 'unsignedInt',
    tags:
      {
        name: $localize`Max photo items`,
        priority: ConfigPriority.underTheHood
      },
    description: $localize`Maximum number autocomplete items shown per photo category.`
  })
  fileName: number = 2;

  @ConfigProperty({
    type: 'unsignedInt',
    tags:
      {
        name: $localize`Max directory items`,
        priority: ConfigPriority.underTheHood
      },
    description: $localize`Maximum number autocomplete items shown per directory category.`
  })
  directory: number = 2;

  @ConfigProperty({
    type: 'unsignedInt',
    tags:
      {
        name: $localize`Max caption items`,
        priority: ConfigPriority.underTheHood
      },
    description: $localize`Maximum number autocomplete items shown per caption category.`
  })
  caption: number = 3;

  @ConfigProperty({
    type: 'unsignedInt',
    tags:
      {
        name: $localize`Max keyword items`,
        priority: ConfigPriority.underTheHood
      },
    description: $localize`Maximum number autocomplete items shown per keyword category.`
  })
  keyword: number = 5;
}

@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class AutoCompleteConfig {
  @ConfigProperty({
    tags:
      {
        name: $localize`Enable Autocomplete`,
        priority: ConfigPriority.advanced
      },
    description: $localize`Show hints while typing search query.`
  })
  enabled: boolean = true;

  @ConfigProperty({
    tags:
      {
        name: $localize`Max items per category`,
        priority: ConfigPriority.underTheHood
      },
    description: $localize`Maximum number autocomplete items shown per category.`
  })
  ItemsPerCategory: AutoCompleteItemsPerCategoryConfig = new AutoCompleteItemsPerCategoryConfig();

  @ConfigProperty({
    type: 'unsignedInt',
    tags:
      {
        name: $localize`Cache timeout`,
        priority: ConfigPriority.underTheHood,
        unit: 'ms'
      },
    description: $localize`Autocomplete cache timeout. `
  })
  cacheTimeout: number = 1000 * 60 * 60;
}

@SubConfigClass({tags: {client: true}, softReadonly: true})
export class ClientSearchConfig {
  @ConfigProperty({
    tags:
      {
        name: $localize`Enable`,
        priority: ConfigPriority.advanced
      },
    description: $localize`Enables searching.`
  })
  enabled: boolean = true;
  @ConfigProperty({
    type: 'unsignedInt',
    tags:
      {
        name: $localize`Cache timeout`,
        priority: ConfigPriority.underTheHood,
        unit: 'ms'
      },
    description: $localize`Search cache timeout.`
  })
  searchCacheTimeout: number = 1000 * 60 * 60;
  @ConfigProperty({
    tags:
      {
        name: $localize`Autocomplete`,
        priority: ConfigPriority.advanced
      },
  })
  AutoComplete: AutoCompleteConfig = new AutoCompleteConfig();
  @ConfigProperty({
    type: 'unsignedInt',
    tags:
      {
        name: $localize`Maximum media result`,
        priority: ConfigPriority.advanced
      },
    description: $localize`Maximum number of photos and videos that are listed in one search result.`
  })
  maxMediaResult: number = 10000;
  @ConfigProperty({
    type: 'unsignedInt', tags:
      {
        name: $localize`Maximum directory result`,
        priority: ConfigPriority.advanced
      },
    description: $localize`Maximum number of directories that are listed in one search result.`
  })
  maxDirectoryResult: number = 200;
  @ConfigProperty({
    tags:
      {
        name: $localize`List directories`,
        priority: ConfigPriority.advanced
      },
    description: $localize`Search returns also with directories, not just media.`
  })
  listDirectories: boolean = false;
  @ConfigProperty({
    tags:
      {
        name: $localize`List metafiles`,
        priority: ConfigPriority.advanced
      },
    description: $localize`Search also returns with metafiles from directories that contain a media file of the matched search result.`,
  })
  listMetafiles: boolean = true;
}

@SubConfigClass({tags: {client: true}, softReadonly: true})
export class ClientAlbumConfig {
  @ConfigProperty({
    tags:
      {
        name: $localize`Enable`,
        priority: ConfigPriority.advanced
      }
  })
  enabled: boolean = true;


  @ConfigProperty({
    type: UserRoles, tags: {
      name: $localize`Albums listing right`,
      priority: ConfigPriority.underTheHood
    },
    description: $localize`Required minimum right to show the albums tab.`
  })
  readAccessMinRole: UserRoles = UserRoles.User;
}




@SubConfigClass({tags: {client: true}, softReadonly: true})
export class SVGIconConfig {

  @ConfigProperty({
    tags: {
      name: $localize`SVG icon viewBox`,
      priority: ConfigPriority.advanced
    },
    description: $localize`SVG path viewBox. See: https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/viewBox`,
  })
  viewBox: string = '0 0 512 512';
  @ConfigProperty({
    tags: {
      name: $localize`SVG Items`,
      priority: ConfigPriority.advanced
    },
    description: $localize`Content elements (paths, circles, rects) of the SVG icon. Icons used on the map: fontawesome.com/icons.`,
  })
  items: string = '';

  constructor(viewBox: string = '0 0 512 512', items: string = '') {
    this.viewBox = viewBox;
    this.items = items;
  }
}





export enum NavigationLinkTypes {
  gallery = 1, albums, search, url
}

@SubConfigClass({tags: {client: true}, softReadonly: true})
export class NavigationLinkConfig {
  @ConfigProperty({
    type: NavigationLinkTypes,
    tags: {
      name: $localize`Type`,
      priority: ConfigPriority.advanced
    } as TAGS
  })
  type: NavigationLinkTypes = NavigationLinkTypes.gallery;
  @ConfigProperty({
    type: 'string',
    tags: {
      name: $localize`Name`,
      priority: ConfigPriority.advanced
    }
  })
  name?: string;
  @ConfigProperty({
    type: 'object',
    tags: {
      name: $localize`SearchQuery`,
      priority: ConfigPriority.advanced,
      uiType: 'SearchQuery',
      relevant: (c: NavigationLinkConfig) => c.type === NavigationLinkTypes.search
    }
  })
  SearchQuery?: SearchQueryDTO;
  @ConfigProperty({
    type: 'string',
    tags: {
      name: $localize`Url`,
      priority: ConfigPriority.advanced,
      relevant: (c: NavigationLinkConfig) => c.type === NavigationLinkTypes.url
    }
  })
  url?: string;


  constructor(type: NavigationLinkTypes = NavigationLinkTypes.gallery,
              name?: string, SearchQuery?: SearchQueryDTO, url?: string) {

    this.type = type;
    this.name = name;
    this.SearchQuery = SearchQuery;
    this.url = url;
  }
}


@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class ClientSortingConfig implements SortingMethod {
  @ConfigProperty({
    type: SortByTypes,
    tags: {
      name: $localize`Method`,
    },
  })
  method: number = SortByTypes.Date;
  @ConfigProperty({
    tags: {
      name: $localize`Ascending`,
    },
  })
  ascending: boolean = true;

  constructor(method: number = SortByTypes.Date, ascending: boolean = true) {
    this.method = method;
    this.ascending = ascending;
  }
}




@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class ClientGroupingConfig implements GroupingMethod {
  @ConfigProperty({
    type: GroupByTypes,
    tags: {
      name: $localize`Method`,
    },
  })
  method: number = GroupByTypes.Date;
  @ConfigProperty({
    tags: {
      name: $localize`Ascending`,
    },
  })
  ascending: boolean = true;

  constructor(method: number = GroupByTypes.Date, ascending: boolean = true) {
    this.method = method;
    this.ascending = ascending;
  }
}


@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class NavBarSortingAndGroupingConfig {

  @ConfigProperty({
    type: ClientSortingConfig,
    tags: {
      name: $localize`Default sorting`,
      priority: ConfigPriority.advanced,
    },
    description: $localize`Default sorting method for photo and video in a directory results.`
  })
  defaultPhotoSortingMethod: ClientSortingConfig = new ClientSortingConfig(SortByTypes.Date, true);

  @ConfigProperty({
    type: ClientSortingConfig,
    tags: {
      name: $localize`Default search sorting`,
      priority: ConfigPriority.advanced,
    },
    description: $localize`Default sorting method for photo and video in a search results.`
  })
  defaultSearchSortingMethod: ClientSortingConfig = new ClientSortingConfig(SortByTypes.Date, false);

  @ConfigProperty({
    type: ClientGroupingConfig,
    tags: {
      name: $localize`Default grouping`,
      githubIssue: 706,
      priority: ConfigPriority.advanced,
    } as TAGS,
    description: $localize`Default grouping method for photo and video in a directory results.`
  })
  defaultPhotoGroupingMethod: ClientGroupingConfig = new ClientGroupingConfig(GroupByTypes.Date, true);

  @ConfigProperty({
    type: ClientGroupingConfig,
    tags: {
      name: $localize`Default search grouping`,
      githubIssue: 706,
      priority: ConfigPriority.advanced,
    },
    description: $localize`Default grouping method for photo and video in a search results.`
  })
  defaultSearchGroupingMethod: ClientGroupingConfig = new ClientGroupingConfig(GroupByTypes.Date, false);

}

@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class NavBarConfig {
  @ConfigProperty({
    tags: {
      name: $localize`Download Zip`,
      priority: ConfigPriority.advanced,
      githubIssue: 52
    },
    description: $localize`Enable zipped download of the listed directory or search results.`
  })
  enableDownloadZip: boolean = true;

  @ConfigProperty({
    tags: {
      name: $localize`Directory flattening`,
      priority: ConfigPriority.advanced,
      experimental: true,
      githubIssue: 174
    },
    description: $localize`Adds a button to flatten the file structure, by listing the content of all subdirectories. (Won't work if the gallery has multiple folders with the same path.)`
  })
  enableDirectoryFlattening: boolean = false;

  @ConfigProperty({
    type: GridSizes,
    tags: {
      name: $localize`Default grid size`,
      githubIssue: 716,
      priority: ConfigPriority.advanced,
    },
    description: $localize`Default grid size that is used to render photos and videos.`
  })
  defaultGidSize: GridSizes = GridSizes.medium;


  @ConfigProperty({
    tags: {
      name: $localize`Show item count`,
      priority: ConfigPriority.underTheHood
    },
    description: $localize`Shows the number photos and videos on the navigation bar.`,
  })
  showItemCount: boolean = true;

  @ConfigProperty({
    arrayType: NavigationLinkConfig,
    tags: {
      name: $localize`Links`,
      priority: ConfigPriority.advanced,
      githubIssue: 174
    },
    description: $localize`Visible links in the top menu.`
  })
  links: NavigationLinkConfig[] = [
    new NavigationLinkConfig(NavigationLinkTypes.gallery),
    new NavigationLinkConfig(NavigationLinkTypes.albums),
  ];
  @ConfigProperty({
    tags: {
      name: $localize`Navbar show delay`,
      priority: ConfigPriority.underTheHood
    },
    type: 'positiveFloat',
    description: $localize`Ratio of the page height, you need to scroll to show the navigation bar.`,
  })
  NavbarShowDelay: number = 0.30;
  @ConfigProperty({
    tags: {
      name: $localize`Navbar hide delay`,
      priority: ConfigPriority.underTheHood
    },
    type: 'positiveFloat',
    description: $localize`Ratio of the page height, you need to scroll to hide the navigation bar.`,
  })
  NavbarHideDelay: number = 0.15;

  @ConfigProperty({
    tags: {
      name: $localize`Show scroll up button`,
      priority: ConfigPriority.underTheHood
    },
    type: ScrollUpModes,
    description: $localize`Set when the floating scroll-up button should be visible.`,
  })
  showScrollUpButton: ScrollUpModes = ScrollUpModes.mobileOnly;


  @ConfigProperty({
    type: NavBarSortingAndGroupingConfig,
    tags: {
      name: $localize`Sorting and grouping`,
      priority: ConfigPriority.advanced,
    },
  })
  SortingGrouping: NavBarSortingAndGroupingConfig = new NavBarSortingAndGroupingConfig();

}


@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class ClientLightboxTitleConfig {

  @ConfigProperty({
    arrayType: LightBoxTitleTexts,
    tags: {
      name: $localize`Top left titles`,
      priority: ConfigPriority.advanced
    },
  })
  topLeftTitle: LightBoxTitleTexts[] = [LightBoxTitleTexts.title];

  @ConfigProperty({
    arrayType: LightBoxTitleTexts,
    tags: {
      name: $localize`Top left subtitles`,
      priority: ConfigPriority.advanced
    },
  })
  topLeftSubtitle: LightBoxTitleTexts[] = [LightBoxTitleTexts.caption];

  @ConfigProperty({
    arrayType: LightBoxTitleTexts,
    tags: {
      name: $localize`Bottom left titles`,
      priority: ConfigPriority.advanced
    },
  })
  bottomLeftTitle: LightBoxTitleTexts[] = [LightBoxTitleTexts.date];

  @ConfigProperty({
    arrayType: LightBoxTitleTexts,
    tags: {
      name: $localize`Bottom left subtitles`,
      priority: ConfigPriority.advanced
    },
  })
  bottomLeftSubtitle: LightBoxTitleTexts[] = [];
}

@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class AutoUpdateConfig {
  @ConfigProperty({
    tags: {
      name: $localize`Enable auto update`,
      priority: ConfigPriority.advanced,
      experimental: true,
    },
    description: $localize`Enable auto polling for new photos and videos in the gallery.`
  })
  enable: boolean = false;

  @ConfigProperty({
    tags: {
      name: $localize`Interval`,
      priority: ConfigPriority.advanced,
      githubIssue: 1062,
      unit: 's'
    },
    description: $localize`Frequency of the auto polling in seconds.`
  })
  interval: number = 60;
}

@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class ClientLightboxConfig {

  @ConfigProperty({
    tags: {
      name: $localize`Default slideshow speed`,
      priority: ConfigPriority.underTheHood,
      githubIssue: 570,
      unit: 's'
    },
    description: $localize`Default time interval for displaying a photo in the slide show.`
  })
  slideshowSpeed: number = 5;

  @ConfigProperty({
    tags: {
      name: $localize`Always show captions`,
      priority: ConfigPriority.underTheHood,
    },
    description: $localize`If enabled, lightbox will always show caption by default, not only on hover.`
  })
  captionAlwaysOn: boolean = false;
  @ConfigProperty({
    tags: {
      name: $localize`Loop Videos`,
      priority: ConfigPriority.underTheHood,
    },
    description: $localize`If enabled, lightbox will loop videos by default.`
  })
  loopVideos: boolean = false;

  @ConfigProperty({
    tags: {
      name: $localize`Loop Slideshow`,
      priority: ConfigPriority.underTheHood,
    },
    description: $localize`If enabled, lightbox will start from the first photo when it reached the last one.`
  })
  loopSlideshow: boolean = false;

  @ConfigProperty({
    tags: {
      name: $localize`Load full resolution image on zoom.`,
      priority: ConfigPriority.advanced
    },
    description: $localize`Enables loading the full resolution image on zoom in the lightbox (preview).`,
  })
  loadFullImageOnZoom: boolean = true;

  @ConfigProperty({
    tags: {
      name: $localize`Load full image if previews are too small`,
      priority: ConfigPriority.advanced
    },
    description: $localize`When enabled, the lightbox will load the full resolution image if all available preview thumbnails are too small for the current view.`,
  })
  loadFullImageIfPreviewTooSmall: boolean = true;

  @ConfigProperty({
    tags: {
      name: $localize`Titles`,
      priority: ConfigPriority.advanced,
      githubIssue: 801,
    } as TAGS,
    description: $localize`Set these to customize the text (caption, location, etc.) in the lightbox that are always visible over the photo (not in the info panel).`
  })
  Titles: ClientLightboxTitleConfig = new ClientLightboxTitleConfig();
}

@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class ThemeConfig {

  @ConfigProperty({
    tags: {
      name: $localize`Name`,
    } as TAGS,
    description: $localize`Name of the theme`
  })
  name: string;
  @ConfigProperty({
    tags: {
      name: $localize`Theme`,
    } as TAGS,
    description: $localize`Adds these css settings as it is to the end of the body tag of the page.`
  })
  theme: string;

  constructor(name?: string, theme?: string) {
    this.name = name;
    this.theme = theme;
  }
}

@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class ThemesConfig {

  @ConfigProperty({
    tags: {
      name: $localize`Enable`,
      githubIssue: 642
    } as TAGS,
    description: $localize`Enable themes and color modes.`
  })
  enabled: boolean = true;

  @ConfigProperty({
    type: ThemeModes,
    tags: {
      name: $localize`Default theme mode`,
      uiDisabled: (sb: ThemesConfig) => !sb.enabled,
    } as TAGS,
    description: $localize`Sets the default theme mode that is used for the application.`
  })
  defaultMode: ThemeModes = ThemeModes.auto;

  @ConfigProperty({
    type: 'string',
    tags: {
      name: $localize`Selected theme`,
      uiDisabled: (sb: ThemesConfig) => !sb.enabled,
      uiType: 'ThemeSelector'
    } as TAGS,
    description: $localize`Selected theme to use on the site.`
  })
  selectedTheme: 'default' | string = 'classic';

  @ConfigProperty({
    arrayType: ThemeConfig,
    tags: {
      name: $localize`Selected theme CSS`, //this is a 'hack' to the UI settings. UI will only show the selected setting's CSS
      uiDisabled: (sb: ThemesConfig) => !sb.enabled,
      relevant: (c: ThemesConfig) => c.selectedTheme !== 'default',
    } as TAGS,
    description: $localize`Adds these CSS settings as it is to the end of the body tag of the page.`
  })
  availableThemes: ThemeConfig[] = [
    new ThemeConfig(
      'classic',
      ':root nav.navbar {\n' +
      '--bs-navbar-color: rgba(255, 255, 255, 0.55);\n' +
      '--bs-navbar-hover-color: rgba(255, 255, 255, 0.75);\n' +
      '--bs-navbar-disabled-color: rgba(255, 255, 255, 0.25);\n' +
      '--bs-navbar-active-color: #fff;\n' +
      '--bs-navbar-brand-color: #fff;\n' +
      '--bs-navbar-brand-hover-color: #fff;\n' +
      '--bs-bg-opacity: 1;\n' +
      'background-color: rgba(var(--bs-dark-rgb), var(--bs-bg-opacity)) !important;\n' +
      '}'
    )];
}


@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class ClientGalleryConfig {
  @ConfigProperty({
    tags: {
      name: $localize`Cache`,
      priority: ConfigPriority.underTheHood,
    },
    description: $localize`Caches directory contents and search results for better performance.`
  })
  enableCache: boolean = true;
  @ConfigProperty({
    tags: {
      name: $localize`Scroll based thumbnail generation`,
      priority: ConfigPriority.advanced,
    },
    description: $localize`Those thumbnails get higher priority that are visible on the screen.`
  })
  enableOnScrollRendering: boolean = true;

  @ConfigProperty({
    tags: {
      name: $localize`Sort directories by date`,
      priority: ConfigPriority.advanced,
    },
    description: $localize`If enabled, directories will be sorted by date, like photos, otherwise by name. Directory date is the last modification time of that directory not the creation date of the oldest photo.`
  })
  enableDirectorySortingByDate: boolean = false;

  @ConfigProperty({
    tags: {
      name: $localize`Ignore timestamp offsets (use local time)`,
      priority: ConfigPriority.advanced,
    },
    description: $localize`If enabled, timestamp offsets are ignored, meaning that the local times of pictures are used for searching, sorting and grouping. If disabled, global time is used and pictures with no timestamp are assumed to be in UTC (offset +00:00).`
  })
    //DEVELOPER NOTE: The Database model stores the timestamp (creationDate) as milliseconds since 1970-01-01 UTC (global time). And stores and offset (creationDateOffset) as minutes.
    //Ignoring the timestamp for the user is the opposite for the database. If the user wants to ignore the offset, we have to add the offset to the creationDate to give the user the right experience.
  ignoreTimestampOffset: boolean = true;


  @ConfigProperty({
    tags: {
      name: $localize`On scroll thumbnail prioritising`,
      priority: ConfigPriority.underTheHood,
    },
    description: $localize`Those thumbnails will be rendered first that are in view.`
  })
  enableOnScrollThumbnailPrioritising: boolean = true;
  @ConfigProperty({
    tags: {
      name: $localize`Navigation bar`,
      uiIcon: 'ionMenuOutline',
      priority: ConfigPriority.advanced,
    } as TAGS
  })
  NavBar: NavBarConfig = new NavBarConfig();
  @ConfigProperty({
    tags: {
      name: $localize`Caption first naming`,
      priority: ConfigPriority.advanced,
    },
    description: $localize`Show the caption (IPTC 120) tags from the EXIF data instead of the filenames.`
  })
  captionFirstNaming: boolean = false; // shows the caption instead of the filename in the photo grid


  @ConfigProperty({
    tags: {
      name: $localize`Lightbox`,
      uiIcon: 'ionImageOutline',
      priority: ConfigPriority.advanced,
    } as TAGS,
    description: $localize`Photo and video preview window.`
  })
  Lightbox: ClientLightboxConfig = new ClientLightboxConfig();

  @ConfigProperty({
    tags: {
      name: $localize`Themes`,
      uiIcon: 'ionBrushOutline',
      priority: ConfigPriority.advanced,
    } as TAGS,
    description: $localize`Pigallery2 uses Bootstrap 5.3 (https://getbootstrap.com/docs/5.3) for design (css, layout). In dark mode it sets 'data-bs-theme="dark"' to the <html> to take advantage bootstrap's color modes. For theming, read more at: https://getbootstrap.com/docs/5.3/customize/color-modes/`
  })
  Themes: ThemesConfig = new ThemesConfig();


  @ConfigProperty({
    tags: {
      name: $localize`Auto update`,
      priority: ConfigPriority.advanced,
    } as TAGS,
    description: $localize`makes the gallery poll the backend for new photos in the given directory or search`
  })
  AutoUpdate: AutoUpdateConfig = new AutoUpdateConfig();
}

@SubConfigClass({tags: {client: true}, softReadonly: true})
export class ClientVideoConfig {
  @ConfigProperty({
    tags: {
      name: $localize`Enable`,
      priority: ConfigPriority.advanced,
      uiResetNeeded: {db: true}
    }
  })
  enabled: boolean = true;
  @ConfigProperty({
    arrayType: 'string',
    tags: {
      name: $localize`Supported formats with transcoding`,
      priority: ConfigPriority.underTheHood,
      uiDisabled: (sb: ClientVideoConfig) => !sb.enabled,
      uiResetNeeded: {db: true}
    } as TAGS,
    description: $localize`Video formats that are supported after transcoding (with the built-in ffmpeg support).`
  })
  supportedFormatsWithTranscoding: string[] = ['avi', 'mkv', 'mov', 'wmv', 'flv', 'mts', 'm2ts', 'mpg', '3gp', 'm4v', 'mpeg', 'vob', 'divx', 'xvid', 'ts'];
  // Browser-supported video formats
  // Read more: https://www.w3schools.com/html/html5_video.asp
  @ConfigProperty({
    arrayType: 'string',
    tags: {
      name: $localize`Supported formats without transcoding`,
      priority: ConfigPriority.underTheHood,
      uiDisabled: (sb: ClientVideoConfig) => !sb.enabled,
      uiResetNeeded: {db: true}
    },
    description: $localize`Video formats that are supported also without transcoding. Browser supported formats: https://www.w3schools.com/html/html5_video.asp`
  })
  supportedFormats: string[] = ['mp4', 'webm', 'ogv', 'ogg'];

}

@SubConfigClass({tags: {client: true}, softReadonly: true})
export class ClientPhotoConfig {


  @ConfigProperty({
    type: 'unsignedInt', max: 100,
    tags: {
      name: $localize`Map Icon size`,
      unit: 'px',
      priority: ConfigPriority.underTheHood
    },
    description: $localize`Icon size (used on maps).`,
  })
  iconSize: number = 45;

  @ConfigProperty({
    arrayType: 'unsignedInt', tags: {
      name: $localize`Thumbnail and photo preview sizes`,
      priority: ConfigPriority.advanced,
      githubIssue: 806
    } as TAGS,
    description: $localize`Size of the thumbnails and photo previews. The best matching size will be used (smaller for photo and video thumbnail, bigger for photo preview). More sizes give better quality, but use more storage and CPU to render. If size is 240, that shorter side of the thumbnail will be 240 pixels.`,
  })
  thumbnailSizes: number[] = [320, 540, 1080, 2160];

  @ConfigProperty({
    volatile: true,
    description: 'Updated to match the number of CPUs. This manny thumbnail will be concurrently generated.',
  })
  concurrentThumbnailGenerations: number = 1;


  @ConfigProperty({

    tags: {
      name: $localize`Concurrent photo generation limit`,
      priority: ConfigPriority.underTheHood,
      uiResetNeeded: {server: true}
    },
    description: 'By default the app uses the number of cpus -1 concurrent threads to generate thumbnails. Set this number higher than 0 to limit the number of concurrent threads.',
  })
  concurrentThumbnailGenerationsLimit: number = 0;

  @ConfigProperty({
    arrayType: 'string',
    tags: {
      name: $localize`Supported photo formats`,
      priority: ConfigPriority.underTheHood,
      uiResetNeeded: {db: true}
    },
    description: $localize`Photo formats that are supported. Browser needs to support these formats natively. Also sharp (libvips) package should be able to convert these formats.`,
  })
  supportedFormats: string[] = ['gif', 'jpeg', 'jpg', 'jpe', 'png', 'webp', 'svg', 'avif', 'heic', 'dng', 'arw', 'tiff'];

  /**
   * Generates a map for bitwise operation from icon and normal thumbnails
   */
  generateThumbnailMap(): { [key: number]: number } {
    const m: { [key: number]: number } = {};
    [this.iconSize, ...this.thumbnailSizes.sort()].forEach((v, i) => {
      m[v] = Math.pow(2, i + 1);
    });
    return m;
  }

  /**
   * Generates a map for bitwise operation from icon and normal thumbnails
   */
  generateThumbnailMapEntries(): { size: number, bit: number }[] {
    return Object.entries(this.generateThumbnailMap()).map(v => ({size: parseInt(v[0]), bit: v[1]}));
  }
}



@SubConfigClass({tags: {client: true}, softReadonly: true})
export class ClientMediaConfig {
  @ConfigProperty({
    tags: {
      name: $localize`Video`,
      priority: ConfigPriority.advanced
    }
  })
  Video: ClientVideoConfig = new ClientVideoConfig();
  @ConfigProperty({
    tags: {
      name: $localize`Photo`,
      priority: ConfigPriority.advanced
    }
  })
  Photo: ClientPhotoConfig = new ClientPhotoConfig();
}

@SubConfigClass({tags: {client: true}, softReadonly: true})
export class ClientMetaFileConfig {
  @ConfigProperty({
    tags: {
      name: $localize`Markdown files`,
      uiResetNeeded: {db: true},
      priority: ConfigPriority.advanced
    },
    description: $localize`Reads *.md files in a directory and shows the next to the map.`
  })
  markdown: boolean = false;

  @ConfigProperty({
    tags: {
      name: $localize`*.pg2conf files`,
      uiResetNeeded: {db: true},
      priority: ConfigPriority.advanced
    },
    description: $localize`Reads *.pg2conf files (You can use it for custom sorting and saved search (albums)).`
  })
  pg2conf: boolean = true;
  @ConfigProperty({
    arrayType: 'string',
    tags: {
      name: $localize`Supported formats`,
      uiResetNeeded: {db: true},
      priority: ConfigPriority.underTheHood
    },
    description: $localize`The app will read and process these files.`
  })
  supportedFormats: string[] = ['pg2conf', 'md'];
}


@SubConfigClass({tags: {client: true}, softReadonly: true})
export class ClientServiceConfig {

  @ConfigProperty({
    tags: {
      name: $localize`Page title`
    } as TAGS
  })
  applicationTitle: string = 'PiGallery 2';

  @ConfigProperty({
    description: $localize`Public URL of the gallery, used when absolute links are needed (e.g. notifications).`,
    tags: {
      name: $localize`Page public url`,
      hint: typeof window !== 'undefined' ? window?.origin : '',
      uiOptional: true
    } as TAGS
  })
  publicUrl: string = '';

  @ConfigProperty({
    description: $localize`If you access the gallery under a sub url (like: https://mydomain.com/myGallery), set it here. If it is not working you might miss the '/' from the beginning of the url.`,
    tags: {
      name: $localize`Url Base`,
      hint: '/myGallery',
      uiResetNeeded: {server: true},
      priority: ConfigPriority.advanced,
      uiOptional: true,
      githubIssue: 854
    } as TAGS
  })
  urlBase: string = '';

  @ConfigProperty({
    description: 'PiGallery api path.',
    tags: {
      name: $localize`Api path`,
      uiResetNeeded: {server: true},
      priority: ConfigPriority.underTheHood
    }
  })
  apiPath: string = '/pgapi';

  @ConfigProperty({arrayType: 'string', volatile: true})
  languages: string[] | undefined;

  @ConfigProperty({
    description: $localize`Injects the content of this between the <head></head> HTML tags of the app. (You can use it to add analytics or custom code to the app).`,
    tags: {
      name: $localize`Custom HTML Head`,
      priority: ConfigPriority.advanced,
      uiResetNeeded: {server: true},
      githubIssue: 404,
      uiOptional: true
    }
  })
  customHTMLHead: string = '';


  @ConfigProperty({
    type: SVGIconConfig,
    tags: {
      name: $localize`Svg Icon`,
      uiType: 'SVGIconConfig',
      priority: ConfigPriority.advanced,
      githubIssue: 1028,
    } as TAGS,
    description: $localize`Sets the icon of the app. Rendered icons are cached in the tmp folder.`,
  })
    // source: https://icons.getbootstrap.com/
  svgIcon: SVGIconConfig = new SVGIconConfig(`0 0 512 512`, '<path d="m185.92 0.042372c-3.1045 0.19567-6.2676 1.0899-9.1546 3.163-16.085-8.0588-25.565 1.6894-23.504 14.76-5.3047 4.0078-10.768 7.8463-6.3153 20.688-4.8283 4.5113-5.2702 11.17-1.2227 20.894-4.5731 7.1343-3.0927 13.944 1.4676 20.445-5.0506 10.26 3.7514 20.507 6.2389 23.943-0.99909 6.6761-0.49742 13.458 11.016 21.392-1.2207 10.005 5.7492 14.415 12.419 19.045 12.567 8.1824 17.213 7.2406 27.088 10.328l-0.13366-1.1862c-15.833 3e-3 -31.017 6.2997-42.211 17.506l-24.715 24.736c-11.194 11.206-26.378 17.503-42.211 17.506h-34.984c-32.972 3.6e-4 -59.702 26.751-59.701 59.749v179.24c3.6312e-4 32.997 26.729 59.746 59.701 59.747h358.21c32.972-3.6e-4 59.7-26.75 59.701-59.747v-179.24c-0.0162-23.02-13.245-43.983-34.008-53.889 3.0728-1.7781 5.0617-4.3071 6.7327-7.0379 4.1124-1.032 17.438-3.2179 20.159-14.327 7.7661-2.0112 13.273-6.2767 14.255-14.719 9.3465-4.8456 13.285-10.23 12.484-16.792 11.694-7.0704 9.9759-13.526 8.4511-19.912 9.9742-8.687 8.874-22.288-8.6236-26.461-3.1292-12.25-18.501-15.32-20.733-16.133-1.3931-4.0275-3.7026-7.9496-14.353-10.399-4.4451-8.3291-12.211-9.9464-20.904-9.9225-6.4476-10.379-14.548-6.8393-22.216-7.2124-9.6958-7.4917-13.951-3.6525-20.032-3.5572-11.02-6.8739-16.687-2.7782-24.497 0.86675l-6.6602-2.5355c-21.868 3.9146-38.57 22.031-45.765 31.84 0.78895-12.143-0.36806-36.764-14.606-53.831l-6.7327-2.3414c-3.6422-7.8167-5.3526-14.6-18.209-16.423-4.7287-3.9225-5.388-9.6636-17.627-10.162-3.9701-2.9861-7.0841-7.4205-11.972-9.091-2.5588-0.82206-5.6927-0.97346-9.6817 0.32356-6.6078-5.7069-13.63-9.3648-22.385-5.8437-9.7319-4.9749-14.082-3.5883-17.674-1.2668-1.3952-0.50821-7.2885-3.6439-14.018-4.1239-1.0094-0.071996-2.0376-0.084841-3.0724-0.019609zm1.017 13.578c10.104 0.93027 18.591 7.2129 24.705 11.86 3.989-1.297 1.8817-5.4748-0.67601-9.9264 7.4731 3.9321 13.922 8.2611 19.542 13.058 4.4921-1.7738-6e-3 -6.9333-1.6283-10.934 11.32 6.6532 15.299 11.732 19.277 16.811 4.96-2.1534 2.5609-6.4373 1.1326-10.368 7.9224 6.6257 11.087 12.731 14.482 18.808 2.4625-1.6331 5.6853-2.3301 4.5577-8.9008 5.1605 6.0597 8.5191 12.233 10.344 18.398 4.8979-1.076 4.6167-5.1376 5.7471-8.2459 4.8158 7.9142 7.0028 15.201 10.195 22.743 1.3502-0.38818 3.143-2.596 5.5002-6.3575 10.495 21.313 19.172 68.475-19.542 71.864-19.845-33.079-47.35-62.019-80.099-88.028 39.018 41.712 59.701 71.578 68.828 93.932-5.6123 8.2892-13.186 12.888-21.423 15.182h-31.496c-9.0855-1.8937-17.047-4.8048-21.968-6.9301 3.5034-0.26396 6.761-1.0578 8.553-3.265-2.8932-4.1339-16.942-6.6095-24.423-15.054 3.8384 0.62815 5.771 0.45179 8.3395-1.4727-7.7461-5.9015-16.277-11.759-20.149-18.339 3.0088 1.096 5.5764 2.7998 10.448 1.4943-6.3427-7.0404-13.489-13.382-17.696-22.065 4.1118 1.3877 8.4445 3.0751 10.271 1.9806-5.5926-6.9871-9.844-14.035-12.948-21.216 5.3821 2.7304 8.0206 3.0315 9.7326 2.5551-3.457-7.4192-8.6517-14.592-9.4172-22.461 3.6436 2.9772 7.3478 4.8776 10.904 3.8631-0.36036-4.7513-7.3377-10.044-8.4022-21.322 4.3234 2.0148 8.7693 4.2946 10.093 3.6768 0.9645-8.9987-0.93024-14.97-2.5963-20.967 9.547 3.3675 23.877 8.6978 23.48 7.6733zm202.89 68.954c-1.1657 3.2054-4.0535 6.0044-0.89552 10.015 5.3574-3.5486 11.898-6.1175 19.744-7.4399-5.0841 4.3081-3.1624 6.8795-2.228 9.7499 6.5043-2.4708 12.815-5.0123 23.175-5.0887-3.6187 2.0919-8.2066 3.8292-5.7902 8.6694 6.3098-1.3316 12.62-2.6636 25.565-0.47848-3.8128 2.0212-10.67 3.0443-8.2709 7.3281 7.289-0.095 15.142 0.67658 23.357 2.5689-4.9157 1.7295-9.1161 3.6077-6.8934 7.1673 7.6683 0.37321 18.204 1.0216 26.541 6.8085l-7.9768 3.8043c-0.96209 0.52956 13.473 5.5674 22.914 9.2263-5.2605 3.5839-10.415 6.8757-15.456 14.39 0.61731 1.3249 5.4871 2.4391 10.093 3.6768-8.059 7.9545-16.768 7.4235-20.131 10.928 2.0376 3.1622 6.0354 3.9567 10.836 4.0553-5.7375 5.5002-14.227 7.6885-21.64 11.148 1.0057 1.4663 3.2192 2.9338 9.0958 4.3043-6.9901 3.5039-14.773 6.1675-23.545 7.9223 0.73194 1.9166 5.0978 3.5087 9.1389 5.0907-8.7991 3.945-18.346 4.207-27.726 5.5201 2.9287 4.0367 5.9538 4.4791 8.9626 5.575-7.1926 2.5501-17.455 1.4514-27.215 1.0864 0.46776 2.1663 1.3155 3.4454 2.7961 4.6612h-13.75c-5.1274-1.4192-9.4503-2.9189-11.788-2.2747-0.0214 0.78201 0.12538 1.5366 0.37044 2.2747h-6.1841c-2.2143-0.16717-4.4175-0.45785-6.5995-0.87068-17.23-8.2945-37.615-23.515-35.198-47.897 21.35-11.254 56.342-20.728 113.06-27.679-41.792-1.1427-81.452 3.3317-117.9 15.905-27.674-27.57 9.2662-58.115 30.995-67.691-0.70716 4.3624-0.65582 7.2407 0.12836 8.4067 7.2901-3.7246 13.646-7.8991 22.418-10.864zm-186.04 100.82h69.97c7.9167 2e-3 15.508 3.1505 21.105 8.7538l24.717 24.736c16.798 16.816 39.584 26.262 63.343 26.259h34.984c16.486 1.9e-4 29.85 13.375 29.85 29.873v179.24c-1.9e-4 16.499-13.365 29.873-29.85 29.873h-358.21c-16.486-1.8e-4 -29.85-13.375-29.85-29.873v-179.24c1.88e-4 -16.499 13.365-29.873 29.85-29.873h34.984c23.739-0.0128 46.501-9.4579 63.285-26.259l24.775-24.736c5.582-5.5884 13.149-8.736 21.045-8.7538zm35.016 59.749c-57.625 0.10848-104.28 46.889-104.28 104.56 0 57.669 46.656 104.45 104.28 104.56 57.625-0.10848 104.28-46.889 104.28-104.56 0-57.669-46.656-104.45-104.28-104.56zm-164.18 29.873c-8.2429 9e-5 -14.925 6.6874-14.925 14.937 0.03875 8.2218 6.7096 14.866 14.925 14.866s14.886-6.6446 14.925-14.866c-9.1e-5 -8.2493-6.6823-14.937-14.925-14.937zm164.18 0c41.206 0.0135 74.603 33.447 74.603 74.684 0 41.238-33.397 74.671-74.603 74.684-41.206-0.0135-74.603-33.447-74.603-74.684 0-41.238 33.397-74.671 74.603-74.684z"/>');


  @ConfigProperty({
    tags: {
      name: $localize`Reload client on server update`,
      priority: ConfigPriority.underTheHood,
      githubIssue: 1078
    },
    description: $localize`If set the UI will auto reload when client related config changed or the app was restarted (except when the UI shows the settings page).`,
  })
  reloadClientOnServerUpdate: boolean = true;
}


@SubConfigClass({tags: {client: true}, softReadonly: true})
export class ClientUserConfig {

  @ConfigProperty<boolean, ClientConfig>({
    tags: {
      uiResetNeeded: {server: true},
      name: $localize`Password protection`,
    },
    description: $localize`Enables user management with login to password protect the gallery.`,
  })
  authenticationRequired: boolean = true;

  @ConfigProperty({
    type: UserRoles, tags: {
      name: $localize`Default user right`,
      priority: ConfigPriority.advanced,
      uiResetNeeded: {server: true},
      relevant: (c: any) => c.authenticationRequired === false
    },
    description: $localize`Default user right when password protection is disabled.`,
  })
  unAuthenticatedUserRole: UserRoles = UserRoles.Admin;

}



@SubConfigClass<TAGS>({tags: {client: true}, softReadonly: true})
export class ClientConfig {

  @ConfigProperty()
  Server: ClientServiceConfig = new ClientServiceConfig();

  @ConfigProperty()
  Users: ClientUserConfig = new ClientUserConfig();

  @ConfigProperty({
    tags: {
      name: $localize`Gallery`,
      uiIcon: 'ionBrowsersOutline'
    } as TAGS,
  })
  Gallery: ClientGalleryConfig = new ClientGalleryConfig();

  @ConfigProperty()
  Media: ClientMediaConfig = new ClientMediaConfig();

  @ConfigProperty()
  MetaFile: ClientMetaFileConfig = new ClientMetaFileConfig();

  @ConfigProperty({
    tags: {
      name: $localize`Album`,
      uiIcon: 'ionAlbumsOutline',
      uiJob: [{
        job: DefaultsJobs[DefaultsJobs['Album Reset']],
        hideProgress: true
      }]
    } as TAGS,
  })
  Album: ClientAlbumConfig = new ClientAlbumConfig();

  @ConfigProperty({
    tags: {
      name: $localize`Search`,
      uiIcon: 'ionSearchOutline'
    } as TAGS,
  })
  Search: ClientSearchConfig = new ClientSearchConfig();


}
