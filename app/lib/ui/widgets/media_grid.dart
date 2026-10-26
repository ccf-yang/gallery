import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import 'thumbnail.dart';

String humanFileSize(int bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double size = bytes.toDouble();
  var unit = 0;
  while (size >= 1000 && unit < units.length - 1) {
    size /= 1000;
    unit++;
  }
  return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

String humanCount(int count) {
  if (count < 10000) return '$count';
  return '${(count / 1000).toStringAsFixed(1)}k';
}

/// 网格列数：手机竖屏 3 列，横屏/平板按 ~110dp 一个格子算。
int gridCrossAxisCount(double width) {
  final count = (width / 112).floor().clamp(2, 6);
  return count;
}

class FolderTile extends StatelessWidget {
  const FolderTile({super.key, required this.folder, required this.onTap});

  final FolderItem folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141414),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: folder.coverApiPath == null
                  ? const Center(child: Icon(Icons.folder_outlined, color: Colors.white30))
                  : Thumbnail(apiPath: folder.coverApiPath!),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  Text(
                    '${humanCount(folder.mediaCount)} 项 · '
                    '${DateFormat('yyyy-MM-dd').format(folder.lastModified)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MediaTile extends StatelessWidget {
  const MediaTile({super.key, required this.media, required this.onTap});

  final MediaItem media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF141414),
            child: Thumbnail(apiPath: media.apiPath),
          ),
          if (media.isVideo)
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 18),
              ),
            ),
          if (!media.isVideo && media.isRawPhoto)
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Text(
                  'RAW',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
