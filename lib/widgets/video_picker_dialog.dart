import 'package:base_flutter_framework/models/video.dart';
import 'package:flutter/material.dart';

class VideoPickerDialog extends StatefulWidget {
  final List<Video> videos;

  const VideoPickerDialog({
    Key? key,
    required this.videos,
  }) : super(key: key);

  @override
  _VideoPickerDialogState createState() => _VideoPickerDialogState();
}

class _VideoPickerDialogState extends State<VideoPickerDialog> {
  final Set<Video> _selectedVideos = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn video'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.videos.length,
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            return CheckboxListTile(
              title: Text(video.title),
              subtitle: video.thumbnailUrl != null
                  ? Image.network(
                      video.thumbnailUrl!,
                      height: 60,
                      width: 80,
                      fit: BoxFit.cover,
                    )
                  : null,
              value: _selectedVideos.contains(video),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedVideos.add(video);
                  } else {
                    _selectedVideos.remove(video);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedVideos.toList()),
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}