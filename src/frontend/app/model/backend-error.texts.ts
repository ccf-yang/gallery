/**
 * 后端错误文案的中文化。
 *
 * ErrorDTO.message 是后端写死的英文（后端不感知语言，也不该感知），
 * 前端几个显示点（通知条、设置页错误框、作业按钮错误、加载失败提示）会把它原样贴出来。
 * 这里在显示前过一遍：
 *   1) 整句精确匹配
 *   2) 前缀匹配（后端常见 "'Xxx error: ' + 详情" 的拼接形式，保留详情部分）
 *   3) 都不命中就原样返回 —— 宁可留一句英文，也别把语义改错。
 *
 * 每条都用 $localize + @@自定义 id，且原文写英文：这样 en 语言包还是英文，
 * 中文只来自 messages.cn.xlf 的 <target>，不用跑 extract-i18n 也能生效。
 */
export class BackendErrorTexts {
  private static readonly exact: { [en: string]: string } = {
    'credentials not found during login': $localize`:@@beErr.badCredentials:credentials not found during login`,
    'not all parameters are included for loginCredential': $localize`:@@beErr.loginParamsMissing:not all parameters are included for loginCredential`,
    'User not exists': $localize`:@@beErr.userNotExists:User not exists`,
    'User not found': $localize`:@@beErr.userNotFound:User not found`,
    'No entry found': $localize`:@@beErr.noEntry:No entry found`,
    'Invalid token': $localize`:@@beErr.invalidToken:Invalid token`,
    'Server error': $localize`:@@beErr.serverError:Server error`,
    'Unknown server error': $localize`:@@beErr.unknownServerError:Unknown server error`,
    'Unknown server side error': $localize`:@@beErr.unknownServerSide:Unknown server side error`,
    'Error during listing albums': $localize`:@@beErr.listAlbums:Error during listing albums`,
    'Error during deleting albums': $localize`:@@beErr.deleteAlbums:Error during deleting albums`,
    'Error during creating saved search albums': $localize`:@@beErr.createSavedSearch:Error during creating saved search albums`,
    'name or searchQuery field is missing': $localize`:@@beErr.albumFieldMissing:name or searchQuery field is missing`,
    'settings is needed': $localize`:@@beErr.settingsMissing:settings is needed`,
    'Can not get app version': $localize`:@@beErr.appVersion:Can not get app version`,
    'Can not get data version': $localize`:@@beErr.dataVersion:Can not get data version`,
    'Error parsing search query': $localize`:@@beErr.parseSearchQuery:Error parsing search query`,
    'Error during listing the directory': $localize`:@@beErr.listDirectory:Error during listing the directory`,
    'No media found for zip': $localize`:@@beErr.noMediaToZip:No media found for zip`,
    'Error creating search results zip': $localize`:@@beErr.zipSearchResults:Error creating search results zip`,
    'Error during searching': $localize`:@@beErr.searching:Error during searching`,
    'Error while getting statistic': $localize`:@@beErr.statistic:Error while getting statistic`,
    'Can\'t update user settings': $localize`:@@beErr.updateUser:Can't update user settings`,
    'Can\'t start this job while another is running': $localize`:@@beErr.jobBusy:Can't start this job while another is running`,
    'Job running error': $localize`:@@beErr.jobRunningError:Job running error`,
    'Error during getting read access to images folder': $localize`:@@beErr.imagesFolderRead:Error during getting read access to images folder`,
    'At least one thumbnail size is needed': $localize`:@@beErr.thumbnailSizeNeeded:At least one thumbnail size is needed`,
    'Error during initializing SQL DB, check DB connection and settings': $localize`:@@beErr.dbInit:Error during initializing SQL DB, check DB connection and settings`,
    'Thumbnail folder error': $localize`:@@beErr.thumbnailFolder:Thumbnail folder error`,
    'Video support error, switching off..': $localize`:@@beErr.videoSupport:Video support error, switching off..`,
    'Albums support error, switching off..': $localize`:@@beErr.albumsSupport:Albums support error, switching off..`,
    'Images folder error': $localize`:@@beErr.imagesFolder:Images folder error`,
    'Thumbnail settings error': $localize`:@@beErr.thumbnailSettings:Thumbnail settings error`,
    'Search is not supported with these settings. Disabling temporally.': $localize`:@@beErr.searchUnsupported:Search is not supported with these settings. Disabling temporally.`,
    'Cover settings are not valid, resetting search query': $localize`:@@beErr.coverSettings:Cover settings are not valid, resetting search query`,
    'Some Tasks are not supported with these settings. Disabling temporally.': $localize`:@@beErr.tasksUnsupported:Some Tasks are not supported with these settings. Disabling temporally.`,
    'Jobs error. Resetting config to default for now to let the app start up.': $localize`:@@beErr.jobsReset:Jobs error. Resetting config to default for now to let the app start up.`,
    'Task does not exist': $localize`:@@beErr.taskNotExists:Task does not exist`,
    'Not yet implemented': $localize`:@@beErr.notImplemented:Not yet implemented`,
  };

  /** 形如 "'英文前缀' + : + 详情" 的消息，翻前缀、留详情 */
  private static readonly prefixes: [string, string][] = [
    ['Settings error', $localize`:@@beErr.settingsErrorPrefix:Settings error`],
    ['Invalid search query JSON', $localize`:@@beErr.badSearchJson:Invalid search query JSON`],
    ['Cannot find location', $localize`:@@beErr.locationNotFound:Cannot find location`],
    ['Messenger error', $localize`:@@beErr.messengerError:Messenger error`],
    ['Error while getting statistic', $localize`:@@beErr.statistic:Error while getting statistic`],
    ['Error during generating thumbnail', $localize`:@@beErr.thumbnailError:Error during generating thumbnail`],
    ['Job running error', $localize`:@@beErr.jobRunningError:Job running error`],
    ['Job error', $localize`:@@beErr.jobError:Job error`],
    ["Can't get random photo", $localize`:@@beErr.randomPhoto:Can't get random photo`],
    ["can't find file", $localize`:@@beErr.fileNotFound:can't find file`],
    ['no such file', $localize`:@@beErr.noSuchFile:no such file`],
    ['Images folder not exists', $localize`:@@beErr.imagesFolderMissing:Images folder not exists`],
    ['IconSize has to be >= 0 integer, got', $localize`:@@beErr.iconSize:IconSize has to be >= 0 integer, got`],
    ['Thumbnail size has to be >= 0 integer, got', $localize`:@@beErr.thumbnailSize:Thumbnail size has to be >= 0 integer, got`],
    ['Unknown directory reading error, skipping', $localize`:@@beErr.directoryRead:Unknown directory reading error, skipping`],
    ['Media loading error, skipping', $localize`:@@beErr.mediaLoading:Media loading error, skipping`],
    ['Metafile loading error, skipping', $localize`:@@beErr.metafileLoading:Metafile loading error, skipping`],
    ['Unsupported media type to render thumbnail', $localize`:@@beErr.unsupportedThumbnail:Unsupported media type to render thumbnail`],
    ['Job already exist', $localize`:@@beErr.jobExists:Job already exist`],
    ['Error during processing file', $localize`:@@beErr.processingFile:Error during processing file`],
    ['Messenger does not exist', $localize`:@@beErr.messengerNotExists:Messenger does not exist`],
    ['Messenger already exist', $localize`:@@beErr.messengerExists:Messenger already exist`],
  ];

  /**
   * @param message 后端给的英文消息（可能带拼接的详情）
   * @return 当前语言下的消息；识别不出来时原样返回
   */
  public static localize(message: any): any {
    if (!message || typeof message !== 'string') {
      // 拦截器那边可能传进来的是对象或 undefined，原样退回，别在这里抛异常
      return message;
    }
    // 用 hasOwnProperty 取，避免消息恰好等于 toString / constructor 之类的键名时取到原型上的方法
    // 后端的部分文案末尾带空格，按去掉首尾空格后的形式匹配
    const msg = message.trim();
    const hit = Object.prototype.hasOwnProperty.call(BackendErrorTexts.exact, msg)
      ? BackendErrorTexts.exact[msg]
      : null;
    if (typeof hit === 'string' && hit) {
      return hit;
    }
    for (const pair of BackendErrorTexts.prefixes) {
      if (msg.startsWith(pair[0])) {
        const rest = msg.slice(pair[0].length).replace(/^[:\s]+/, '');
        return rest ? pair[1] + ': ' + rest : pair[1];
      }
    }
    return message;
  }
}
